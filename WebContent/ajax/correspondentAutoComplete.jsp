<%@page language="java" contentType="application/json;charset=UTF-8"%>
<%@page import="edu.stanford.muse.AddressBookManager.AddressBook"%>
<%@page import="edu.stanford.muse.AddressBookManager.Contact"%>
<%@ page import="edu.stanford.muse.index.Archive" %>
<%@ page import="edu.stanford.muse.webapp.HTMLUtils" %>
<%@ page import="edu.stanford.muse.webapp.JSPHelper" %>
<%@ page import="edu.stanford.muse.util.Util" %>
<%@ page import="org.json.JSONArray" %><%@ page import="org.json.JSONObject"%><%@ page import="java.util.LinkedHashSet"%><%@ page import="java.util.Set"%>
<% 
	String query = request.getParameter("query");
	query = query.toLowerCase();
    if (query != null) {
        if (query.contains(";"))
            query = query.substring(query.lastIndexOf(";")+1);
        query = query.trim();
    }

	JSONObject obj = new JSONObject();
	obj.put("query", query);

	JSONArray suggestions = new JSONArray();
	obj.put("suggestions",suggestions);

    int MAX_SUGGESTIONS = HTMLUtils.getIntParam(request, "MAX_SUGGESTIONS", 5);

    Archive archive = JSPHelper.getArchive(request);
    if (archive == null) {
        obj.put("status", 1);
        obj.put("error", "No archive in session");
        out.println (obj);
        JSPHelper.log.info(obj);
        return;
    }
	if (!Util.nullOrEmpty(query) && archive != null) {
		AddressBook addressBook = archive.addressBook;

        int suggestionCount = 0;
        Set<String> seen = new LinkedHashSet<>();
        outer:
		for (Contact c: addressBook.allContacts()){
			Set<String> names = c.getNames();
			if (names != null) {
				for (String name: names) {
					if (name.toLowerCase().contains(query)) {
					    if (seen.contains(name.toLowerCase()))
                            continue;
                        seen.add(name.toLowerCase());

						JSONObject s = new JSONObject();
						s.put("value", name);
						s.put("name", name);
						suggestions.put(s);
						if (++suggestionCount > MAX_SUGGESTIONS)
						    break outer;
					}
				}
			}

			Set<String> emails = c.getEmails();
			if (emails != null) {
				for (String email: emails) {
					if (email.toLowerCase().contains(query)) {
						JSPHelper.log.info("Adding name: " + names);
						JSONObject s = new JSONObject();
						s.put("value", email); // just get the first of the possibly many names
						s.put("name", email); // just get the first of the possibly many names
						suggestions.put(s);
						if (++suggestionCount > MAX_SUGGESTIONS)
						    break outer;
					}
				}
			}
		}
	}
	response.getWriter().write(obj.toString());
%>