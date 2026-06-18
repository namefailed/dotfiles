#!/usr/bin/env python3
#
# Executes python-readability on current page and opens the summary as new tab.
#
# Depends on the python-readability package, or its fork:
#
#   - https://github.com/buriy/python-readability
#   - https://github.com/bookieio/breadability
#
# Usage:
#   :spawn --userscript readability
#
import os

tmpfile = os.path.join(
    os.environ.get("QUTE_DATA_DIR", os.path.expanduser("~/.local/share/qutebrowser")),
    "userscripts/readability.html",
)

if not os.path.exists(os.path.dirname(tmpfile)):
    os.makedirs(os.path.dirname(tmpfile))

# Styling for dynamic window margin scaling and line height
HEADER = """<!DOCTYPE html>
<html>
<head>
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>{title}</title>
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8"/>
    <style type="text/css">
        body {{
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
            margin: 0 auto;
            max-width: 720px;
            line-height: 1.7;
            padding: 2.5rem 1.5rem;
            font-size: 17px;
        }}

        h1, h2, h3, h4 {{
            line-height: 1.3;
            margin-top: 2.5rem;
            margin-bottom: 1rem;
            font-weight: 600;
        }}

        h1 {{ font-size: 1.9em; }}
        h2 {{ font-size: 1.5em; }}
        h3 {{ font-size: 1.2em; }}

        img, figure, video, iframe, svg {{
            display: block;
            margin: 2rem auto;
            max-width: 100%;
            height: auto;
        }}

        figcaption {{
            text-align: center;
            font-size: 0.85em;
            opacity: 0.7;
            margin-top: -1.5rem;
            margin-bottom: 2rem;
        }}

        pre, code {{
            font-family: "CaskaydiaCove NFM", "Consolas", "Monaco", monospace;
            font-size: 0.9em;
            background: rgba(128,128,128,0.12);
            border-radius: 5px;
        }}

        pre {{
            padding: 1rem 1.2rem;
            overflow-x: auto;
            line-height: 1.5;
            margin: 1.5rem 0;
        }}

        code {{ padding: 0.15em 0.35em; }}
        pre > code {{ padding: 0; background: none; }}

        blockquote {{
            border-left: 3px solid currentColor;
            margin: 1.5rem 0;
            padding: 0.5rem 0 0.5rem 1.2rem;
            opacity: 0.85;
            font-style: italic;
        }}

        table {{
            width: 100%;
            border-collapse: collapse;
            margin: 1.5rem 0;
            font-size: 0.95em;
        }}

        th, td {{
            border: 1px solid rgba(128,128,128,0.3);
            padding: 0.6rem 0.8rem;
            text-align: left;
        }}

        th {{
            font-weight: 600;
            background: rgba(128,128,128,0.08);
        }}

        a {{ text-decoration: underline; }}
        a:hover {{ opacity: 0.8; }}

        p, li {{ margin: 0.8rem 0; }}
        ul, ol {{ padding-left: 1.5rem; }}

        hr {{
            border: none;
            border-top: 1px solid rgba(128,128,128,0.3);
            margin: 2.5rem 0;
        }}
    </style>
</head>
"""

with open(os.environ["QUTE_HTML"], "r", encoding="utf-8") as source:
    data = source.read()

    try:
        from breadability.readable import Article as reader

        doc = reader(data, os.environ["QUTE_URL"])
        title = doc._original_document.title
        content = HEADER.format(title=title) + doc.readable + "</html>"
    except ImportError:
        from readability import Document

        doc = Document(data)
        title = doc.title()
        content = doc.summary().replace("<html>", HEADER.format(title=title))

    # add a class to make styling the page easier
    content = content.replace("<body>", '<body class="qute-readability">')

    with open(tmpfile, "w", encoding="utf-8") as target:
        target.write(content.lstrip())

    with open(os.environ["QUTE_FIFO"], "w") as fifo:
        fifo.write("open -t {}".format(tmpfile))
