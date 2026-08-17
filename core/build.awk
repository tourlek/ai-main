# Tier compiler for ai-main prompt sources.
#
#   awk -v tier=lean -f core/build.awk <file>
#
# A content line tagged  <!--min-->   ships in every tier.
# A content line tagged  <!--lean-->  ships in lean and full.
# An untagged content line ships in full only.
# Markers are stripped from the output, so `tier=full` reproduces the source byte for byte.
#
# Headings and blank lines are buffered verbatim and only emitted once a content line under
# them survives the filter. A heading whose whole section was filtered out is dropped along
# with its blank lines, so smaller tiers get no empty sections and no double blank lines.

BEGIN { rank["min"] = 0; rank["lean"] = 1; rank["full"] = 2; want = rank[tier]; n = 0 }

function heading_level(s,   k) {
    k = 0
    while (substr(s, k + 1, 1) == "#") k++
    return (substr(s, k + 1, 1) == " ") ? k : 0
}

function flush(   i, prev_blank, is_blank) {
    prev_blank = 0
    for (i = 1; i <= n; i++) {
        is_blank = (buf[i] ~ /^[[:space:]]*$/)
        # In reduced tiers a filtered-out paragraph leaves its surrounding blanks behind;
        # collapse the run so the output does not gain double blank lines.
        if (is_blank && prev_blank && want < 2) continue
        print buf[i]
        prev_blank = is_blank
    }
    n = 0
    delete start
}

{
    line = $0
    lvl = heading_level(line)

    if (lvl > 0) {
        # This heading supersedes an unflushed sibling at the same level: drop that
        # sibling and everything buffered under it.
        if (lvl in start) n = start[lvl] - 1
        for (k in start) if (k + 0 > lvl) delete start[k]
        buf[++n] = line
        start[lvl] = n
        next
    }

    if (line ~ /^[[:space:]]*$/) { buf[++n] = line; next }

    if (line ~ /<!--min-->[[:space:]]*$/)       tag = 0
    else if (line ~ /<!--lean-->[[:space:]]*$/) tag = 1
    else                                        tag = 2
    if (tag > want) next

    sub(/[[:space:]]*<!--(min|lean)-->[[:space:]]*$/, "", line)
    flush()
    print line
}
