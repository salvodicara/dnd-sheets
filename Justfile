# D&D Sheets — dev tasks

# Extract JS from index.html and syntax-check with node
check:
    @sed -n '/<script>/,/<\/script>/p' index.html | sed '1d;$d' > /tmp/dnd-check.js \
        && node --check /tmp/dnd-check.js \
        && sed -n '/<script>$/,/<\/script>/p' assistant.html | sed '1d;$d' > /tmp/dnd-check-asst.js \
        && node --check /tmp/dnd-check-asst.js \
        && echo "✓ Syntax OK"

# Open in default browser
open:
    open index.html

# Check then open
run: check open
