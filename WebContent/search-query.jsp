<%@page contentType="text/html; charset=UTF-8"%>
<%@page trimDirectiveWhitespaces="true"%>
<%@ page import="edu.stanford.muse.index.ArchiveReaderWriter" %>
<%@include file="getArchive.jspf" %>
<%
	String archiveID = ArchiveReaderWriter.getArchiveIDForArchive(archive);
%>
<!DOCTYPE HTML>
<html>
<head>
	<meta name="viewport" content="width=device-width, initial-scale=1">
	<title>Search</title>
	
	<link rel="icon" type="image/png" href="images/epadd-favicon.png">
	<link rel="stylesheet" href="bootstrap/dist/css/bootstrap.min.css">
	<jsp:include page="css/css.jsp"/>
	<link rel="stylesheet" href="css/sidebar.css">
	<link rel="stylesheet" href="css/main.css">

	<script src="js/jquery.js"></script>
	
	<!-- Optional theme -->
	<script type="text/javascript" src="bootstrap/dist/js/bootstrap.min.js"></script>

	<script src="js/modernizr.min.js"></script>
	<script src="js/sidebar.js"></script>

	<script src="js/muse.js"></script>
	<script src="js/epadd.js"></script>
	<style>
		td > div {
			padding: 5px;
		}

		.option {
			margin-right: 15px;
		}

		.underlined-header { border-bottom: solid 4px #0175bc; }
		.search-header { font-size: 100%; cursor: pointer; padding-bottom:5px;}
	</style>
</head>
<body>
<jsp:include page="header.jspf"/>
<script>epadd.nav_mark_active('Search');</script>


<div class="nav-toggle1 sidebar-icon">
	<img src="images/sidebar.png" alt="sidebar">
</div>
<nav class="menu1" role="navigation">
	<h2><b>Searching email</b></h2>
	<!--close button-->
	<a class="nav-toggle1 show-nav1" href="#">
		<img src="images/close.png" class="close" alt="close">
	</a>

	<div class="search-tips" style="display:block">

		<% if (ModeConfig.isAppraisalMode() || ModeConfig.isProcessingMode() || ModeConfig.isDeliveryMode()) { %>

			Simple search: Search for keywords or phrases. Supports Boolean searching.
			<br/><br/>

			Multi-entity search: Type or paste a text block then click search to search the email archive for all matching entities. Underlined terms have been identified by ePADD as entities. Highlighted terms represent entities that also appear in the email archive. Click on a highlighted term to view a brief list of messages, linked to the resulting set.
			<br/><br/>


			Multi-term search: Type or past a list of terms (one term per line) then click search to search the email archive for all matching terms. Highlighted terms also appear in the email archive. Click on a highlighted term to view a brief list of messages, linked to the resulting set.
			<br/><br/>

			Advanced search: Search using a range of advanced parameters, specifying terms, entities, correspondents, attachments, annotations, labels, and more.
			<br/><br/>

		<% } else if (ModeConfig.isDiscoveryMode()) { %>
			Simple search: Search for correspondents or entities. Supports Boolean searching.
			<br/><br/>

			Multi-entity search: Type or paste a text block then click search to search the email archive for all matching entities. Underlined terms have been identified by ePADD as entities. Highlighted terms represent entities that also appear in the email archive. Click on a highlighted term to view a brief list of messages, linked to the resulting set.
			<br/><br/>

			Advanced search: Search using a range of advanced parameters, specifying entities, correspondents, and more.
			<br/><br/>
		<% } %>
	</div>
</nav>

<%writeProfileBlock(out, archive, "Search");%>
<br/>
<br/>

<div style="text-align:center; margin:auto; width:600px;">
	<div style="width:100%;margin-bottom:20px;">
		<a id="simple-search-header"  class="underlined-header search-header" >Simple search</a>
		<%--<a id="query-generator-header" class="search-header" style="margin-left:40px;">Query Generator</a>--%>
		<a id="query-generator-header" class="search-header" style="margin-left:40px;">Multi-Entity Search</a>
		<a id="term-search-header" class="search-header" style="margin-left:40px;">Multi-Term Search</a>

	</div>

	<div id="simple-search" style="text-align:center">
		<form method="get" action="browse">
	<%--		hidden input field to pass archiveID to the server. This is a common pattern used to pass
			//archiveID in all those forms where POST was used to invoke the server page.
	--%>
		<input type="hidden" value="<%=archiveID%>" class="form-control" type="text" name="archiveID"/>
			<input name="term" size="80" placeholder="search query"/>
			<div style="display:none">
				<input type="hidden" name="adv-search"/>
				<input type="checkbox" name="termBody" checked>
				<input type="checkbox" name="termSubject" checked>
				<input type="checkbox" name="termAttachments" checked>
				<input type="checkbox" name="termOriginalBody" checked>
			</div>
			<br/>
			<br/>

			<button class="btn btn-cta" style="margin-top: 5px" type="submit" name="Go">Search <i class="icon-arrowbutton"></i></button>

		</form>
	</div>
<p>

	<div style="display:none" id="term-search">
		<form method="post" action="query-generator" accept-charset="UTF-8">
			<input type="hidden" value="<%=archiveID%>" class="form-control" type="text" name="archiveID"/>
			<textarea placeholder="Type or paste terms here (one line per term) to search the email archive for all matching terms. Following the search, select a highlighted term to view related messages." name="refTextTerms" id="refTextTerms" cols="80" rows="10"></textarea>
			<br/>
			<div style="text-align:center">
				<button class="btn btn-cta" style="margin-top: 5px" type="submit" name="Go">Search <i class="icon-arrowbutton"></i></button>
			</div>
		</form>
	</div>

	<div style="display:none" id="query-generator">
		<form method="post" action="query-generator" accept-charset="UTF-8">
			<input type="hidden" value="<%=archiveID%>" class="form-control" type="text" name="archiveID"/>
			<textarea placeholder="Type or paste text here to search the email archive for all matching entities. Following the search, select a highlighted entity to view related messages." name="refText" id="refText" cols="80" rows="10"></textarea>
			<br/>
			<div style="text-align:center">
				<button class="btn btn-cta" style="margin-top: 5px" type="submit" name="Go">Search <i class="icon-arrowbutton"></i></button>
			</div>
		</form>
	</div>

	<br/>
	Need more search options? Try <a href="advanced-search?archiveID=<%=archiveID%>">Advanced Search</a>, or <a href="bulk-upload?archiveID=<%=archiveID%>">Upload</a> a list of correspondents.
</div>

<script>
	$(document).ready(function() {
		$('#simple-search-header').addClass('underlined-header');
		$('#simple-search-header').click(function() {
			$('#simple-search-header').addClass('underlined-header');
			$('#query-generator-header').removeClass('underlined-header');
            $('#term-search-header').removeClass('underlined-header');
            $('#simple-search').show();
			$('#query-generator').hide();
			$('#term-search').hide();
		});
		$('#query-generator-header').click(function() {
			$('#query-generator-header').addClass('underlined-header');
			$('#simple-search-header').removeClass('underlined-header');
            $('#term-search-header').removeClass('underlined-header');
            $('#simple-search').hide();
			$('#term-search').hide();
			$('#query-generator').show();
		});
        $('#term-search-header').click(function() {
            $('#term-search-header').addClass('underlined-header');
            $('#simple-search-header').removeClass('underlined-header');
            $('#query-generator-header').removeClass('underlined-header');
            $('#simple-search').hide();
            $('#query-generator').hide();
            $('#term-search').show();
        });
	});

</script>

<p>
<jsp:include page="footer.jsp"/>
</body>
</html>
