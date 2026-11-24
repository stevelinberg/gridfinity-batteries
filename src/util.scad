// Small helpers for the key/value data tables.

// Value for `key` in a list of [key, value] pairs, or `dflt`.
function kv(list, key, dflt=undef) =
    let(m = [for (p = list) if (p[0] == key) p[1]])
    len(m) > 0 ? m[0] : dflt;

// Look up a bin property, falling back to BIN_DEFAULTS.
function bin_prop(bin, key, defaults) = kv(bin, key, kv(defaults, key));

// Element i of v if v is a list, else v itself.
function at(v, i) = is_list(v) ? v[i] : v;

function vmax(v) = is_list(v) ? max(v) : v;
