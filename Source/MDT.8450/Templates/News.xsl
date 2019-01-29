<?xml version="1.0" encoding="ISO-8859-1"?>
<xsl:stylesheet version="1.0"
xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:fo="http://www.w3.org/1999/XSL/Format" >

<xsl:output method='html' version='1.0' encoding='UTF-8' indent='yes'/>
 
<xsl:template match="/">
	<html>
	<head>
		<link href="../Documentation/html/scripts/demo.css" rel="stylesheet" type="text/css" />
		<img src="../Documentation/images/MIC_059_masthead.jpg" width="771" height="100" border="0" />
	</head>
	<body topmargin="0" leftmargin="0" rightmargin="0" bottommargin="0">

	<table cellSpacing="9" cellPadding="1" border="0">
		<xsl:for-each select="news/newsItem">
			<tr>
				<td>
					<b>
						<a target="_blank" style="font-size: 10px; color: #0033CC;">
							<xsl:attribute name="href">
								<xsl:value-of select="url" />
							</xsl:attribute>
							<xsl:value-of select="title" disable-output-escaping="yes" />
						</a>
					</b>
        				<div style="font-size: 10px;"><xsl:value-of select="description" disable-output-escaping="yes" /></div>
				</td>
			</tr>
		</xsl:for-each>
	</table>

	</body>
	</html>
</xsl:template>
</xsl:stylesheet>
