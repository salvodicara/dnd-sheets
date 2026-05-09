# D&D Sheets — dev tasks

# Extract JS from all pages and syntax-check with node
check:
    @sed -n '/<script>$/,/<\/script>/p' index.html | sed '1d;$d' > /tmp/dnd-check.js \
        && node --check /tmp/dnd-check.js \
        && { sed -n '/<script>$/,/<\/script>/p' assistant.html | sed '1d;$d'; \
             sed -n '/<script>\/\//,/<\/script>/p' assistant.html | sed '1d;$d'; } > /tmp/dnd-check-asst.js \
        && node --check /tmp/dnd-check-asst.js \
        && sed -n '/<script>$/,/<\/script>/p' chronicles.html | sed '1d;$d' > /tmp/dnd-check-chr.js \
        && node --check /tmp/dnd-check-chr.js \
        && echo "✓ Syntax OK"

# Check then open in browser
run: check
    open index.html
