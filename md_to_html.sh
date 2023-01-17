#!/bin/sh
#
# convert markdown to html
#
# PRE-REQ: 
# install pandoc templates from here: https://github.com/ryangrose/easy-pandoc-templates
#
# usage: 
#   $ ./md_to_html.sh
#
#   Run from h3-cli root dir
# 

# rm -i `find . -name '*.html' -o -name '*.html.bak'`
# rm `find html -name '*.html' -o -name '*.html.bak'`
rm -Rf html/*
mkdir -p html/guides
cp -R images html/images

for x in `find . -name '*.md'`; do 
    md_name=$x
    html_name=`echo $x | sed 's/[.]md/.html/' | sed 's#^[.]/#html/#'`
    # echo md_name=$md_name, html_name=$html_name
    # pandoc -s --toc --template=~/.pandoc/templates/elegant_bootstrap_menu.html $md_name -o $html_name
    # pandoc -s --toc --template=~/.pandoc/templates/bootstrap_menu.html $md_name -o $html_name
    # pandoc -s --toc --template=~/.pandoc/templates/clean_menu.html $md_name -o $html_name
    # pandoc -s --toc --template=~/.pandoc/templates/easy_template.html $md_name -o $html_name
    pandoc -s --toc --template=~/.pandoc/templates/uikit.html $md_name -o $html_name
    sed -i '' 's/[.]md/.html/' $html_name
    sed -i '' 's#<p>\[\[<em>TOC</em>\]\]</p>##' $html_name
done

