<%@ page language="java" contentType="application/json;charset=UTF-8"%>
<%@page trimDirectiveWhitespaces="true"%>
<%@page language="java" import="edu.stanford.muse.index.EmailDocument"%>
<%@page language="java" import="edu.stanford.muse.lens.Lens"%>
<%@page language="java" import="edu.stanford.muse.lens.LensPrefs"%>
<%@page language="java" import="edu.stanford.muse.ner.tokenize.CICTokenizer"%>
<%@page language="java" import="edu.stanford.muse.util.DictUtils"%>
<%@page language="java" import="edu.stanford.muse.util.Pair"%>
<%@page language="java" import="edu.stanford.muse.util.Triple"%>
<%@page language="java" import="edu.stanford.muse.util.Util"%>
<%@ page import="edu.stanford.muse.webapp.HTMLUtils"%>
<%@ page import="edu.stanford.muse.webapp.JSPHelper"%><%@ page import="org.json.JSONArray"%>
<%@ page import="org.json.JSONObject"%>
<%@ page import="java.util.*"%><%@ page import="edu.stanford.muse.index.Archive"%>
<%//Archive needs to be loaded since NER is archive dependant%>

<%
JSPHelper.setPageUncacheable(response);
	// https://developer.mozilla.org/en/http_access_control
response.setHeader("Access-Control-Allow-Origin", request.getHeader("Origin"));
response.setHeader("Access-Control-Allow-Credentials", "true");
response.setHeader("Access-Control-Allow-Methods", "POST, GET, OPTIONS");
response.setHeader("Access-Control-Allow-Headers", "Origin, X-Requested-With, Content-Type, Accept");

JSONObject result = new JSONObject();
int callout_lines = HTMLUtils.getIntAttr(session, "lens.callout.lines", 3);
result.put("callout_lines", callout_lines);
try {
    response.setContentType("application/json; charset=utf-8");
	String text = request.getParameter("refText");
	String url = request.getParameter("refURL");
	boolean only_term_search=false;
	if(text.toLowerCase().contains("term search result"))
	    only_term_search=true;

	String baseURL = request.getScheme() + "://" + request.getServerName() + ":" + request.getServerPort() + request.getContextPath();
	Collection<EmailDocument> allDocs = (Collection<EmailDocument>) JSPHelper.getSessionAttribute(session, "emailDocs");
    Archive archive = JSPHelper.getArchive(request);
    if (archive == null) {
        JSONObject obj = new JSONObject();
        obj.put("status", 1);
        obj.put("error", "No archive in session");
        out.println (obj);
        JSPHelper.log.info(obj);
        return;
    }

	//Indexer	indexer = archive.indexer;
	if (allDocs == null)
		allDocs = (Collection) archive.getAllDocs();
	
	if (Util.nullOrEmpty(text))
	{
		result.put("displayError", "Please provide some text.");
		return;
	}

	List<Pair<String,Float>> names = new ArrayList<>();
    List<JSONObject> list;

	 if(only_term_search){
        //tokenize text on the basis of \n and add them to names list with 1 as trust value-- (just to make the interface consistent as of entity extraction based search)
        String[] terms = text.split("[\n]");
        for(String term: terms){
            if(Util.nullOrEmpty(term.trim()))
                continue;
            names.add(new Pair(term.trim(),1f));
        }
	 }else{
		Map<String, Float> termFreqMap = new LinkedHashMap<>();

		long ner_start_millis = System.currentTimeMillis();

	//it is not efficient to recognize entities every time, especially since it lags the page by a minute for the first loading of the page.
	//The delay is due to loading of DBpedia into memory.
	//	Pair<Map<Short, Map<String,Double>>, List<Triple<String, Integer, Integer>>> p = nerModel.find(text);
	//	if(p!=null){
	//	    Map<Short,Map<String,Double>> map = p.getFirst();
	//	    if(map!=null){
	//	        for(Short k: map.keySet()){
	//	            if(FeatureDictionary.OTHER==k)
	//                    continue;
	//	            JSPHelper.log.info("Entity type: "+k+", "+map.get(k).size());
	//	            for(String e: map.get(k).keySet()){
	//	                if(map.get(k).get(e)>1.0E-4)
	//	                names.add(new Pair<>(e,new Float(1.0)));
	//	            }
	//	        }
	//	    }
	//	}


		List<Triple<String,Integer,Integer>> tokens = new CICTokenizer().tokenize(text);

		// filter out noisy single-word tokens (in full dict or 5000 dict, or same stem as 5000 dict)
		{
			// if the token is not a multi-word token (doesn't contain space), do some additional checks
			List<Triple<String,Integer,Integer>> newTokens = new ArrayList<>();

			for (Triple<String,Integer,Integer> t: tokens) {
				String token = t.getFirst().toLowerCase();
				if (!token.contains(" ")) {
					// is a common dict word? then don't include
					if (DictUtils.commonDictWords5000.contains(token))
						continue;
					if (DictUtils.fullDictWords.contains(token))
						continue;

					// has the same stem as a common dict word? don't include
	//                String stem = DictUtils.canonicalizeTerm(token, true);
	//                if (DictUtils.commonDictWords5000Stems.contains(stem))
	//                    continue;
				}
				newTokens.add(t);
			}
			tokens = newTokens;
		}

		//tokens.forEach(tok->termFreqMap.put(tok.getFirst(),termFreqMap.getOrDefault(tok.getFirst(),0f)+1f));
		for(Triple<String,Integer,Integer> tok: tokens)
			termFreqMap.put(tok.getFirst(),termFreqMap.getOrDefault(tok.getFirst(),0f)+1f);

		//termFreqMap.entrySet().forEach(e->names.add(new Pair<>(e.getKey(),e.getValue())));
		for(Map.Entry e: termFreqMap.entrySet())
			names.add(new Pair<>((String)e.getKey(),(Float)e.getValue()));

		long ner_end_millis = System.currentTimeMillis();
		JSPHelper.log.info("NER time " + (ner_end_millis - ner_start_millis) + " ms");

		String DATE_FORMAT = "yyyyMMdd";
		JSPHelper.log.info(termFreqMap.size() + " unique name(s) identified");

	}

	LensPrefs lensPrefs = (LensPrefs) JSPHelper.getSessionAttribute(session, "lensPrefs");
	if (lensPrefs == null)
	{
		String cacheDir = (String) JSPHelper.getSessionAttribute(session, "cacheDir");
		if (cacheDir != null)
		{
			lensPrefs = new LensPrefs(cacheDir);
			session.setAttribute("lensPrefs", lensPrefs);
		}
	}
	try {
		long start = System.currentTimeMillis();
		//list = Lens.getHits (names, lensPrefs, indexer, ab, baseURL, allDocs);
		long end = System.currentTimeMillis();
		//JSPHelper.log.info ("normal get hits " + (end - start) + " ms");
		start = end;
		list = Lens.getHitsQuick (names, lensPrefs, archive, baseURL, allDocs);
		end = System.currentTimeMillis();
		//JSPHelper.log.info ("quick get hits " + (end - start) + " ms");
	} catch (Exception e) {
		JSPHelper.log.warn ("Exception getting lens hits " + e);
		Util.print_exception(e, JSPHelper.log);
		list = new ArrayList<>();
	}
	JSPHelper.log.info (list.size() + " hits after sorting");

	JSONArray jsonArray = new JSONArray();
	int index = 0;
	for (JSONObject o: list)
		jsonArray.put(index++, o);

	result.put("results", jsonArray);
	if (Lens.log.isDebugEnabled()) {
		Lens.log.debug (result.toString(4));
	}
} catch (Exception e) {
	result.put("error", "Exception: " + e);
	Util.print_exception (e, JSPHelper.log);
} catch (Error e) {
	// stupid abstract method problem on jetty shows up as an error not as exception
	result.put("error", "Error: " + e);
	Util.print_exception (e, JSPHelper.log);
} finally { 
	out.println (result.toString(4));
}
%>
