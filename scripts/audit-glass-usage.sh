#!/bin/bash
# Audit: ensure no .glassEffect() calls exist outside the GlassKit module
# Covers DESG-02 and DESG-05 enforcement

VIOLATIONS=$(grep -rn "\.glassEffect" BarDown-iOS/BarDown/ --include="*.swift" 2>/dev/null)

if [ -n "$VIOLATIONS" ]; then
    echo "FAIL: .glassEffect() found outside GlassKit module:"
    echo "$VIOLATIONS"
    exit 1
else
    echo "PASS: No .glassEffect() calls found outside GlassKit module"
    exit 0
fi
