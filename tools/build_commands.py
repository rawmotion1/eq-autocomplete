"""
Builds lib/commands.lua (the command list eq-autocomplete suggests from) out of the RedGuides docs.

    python tools/build_commands.py            use the pages cached in tools/cache/ (downloads any missing)
    python tools/build_commands.py --refresh  download all pages again first

Sources (each command's syntax block is HTML highlighted by class: nt = command, nl/no = literal
keyword, nv = placeholder, nv-Required = required placeholder, p = punctuation):
    https://www.redguides.com/docs/commands/                                  every command, grouped by plugin
    https://www.redguides.com/docs/projects/everquest/commands/               EverQuest's own commands
    https://www.redguides.com/docs/projects/macroquest/reference/commands/    MacroQuest core commands

The docs' syntax is hand-written and not always balanced, so the parser is forgiving: unmatched
brackets are closed or ignored, literals that aren't words (examples, punctuation) are dropped.

Output grammar (see lib/grammar.lua for how it is walked):
    a sequence is a Lua array of nodes; a node is one of
      "word"                          a literal keyword
      {v="name", q=1}                 a placeholder (q = the docs show it quoted)
      {alt={seq, seq, ...}, o=1, r=1} a choice; o = optional ([...]), r = may repeat (...)
    each command's g is a group whose alternatives are its syntax lines.
"""
import datetime
import html
import os
import re
import sys
import urllib.request

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(HERE)
CACHE = os.path.join(HERE, 'cache')
OUT = os.path.join(REPO, 'lib', 'commands.lua')

PAGES = [
    ('all', 'https://www.redguides.com/docs/commands/'),
    ('eq', 'https://www.redguides.com/docs/projects/everquest/commands/'),
    ('mq', 'https://www.redguides.com/docs/projects/macroquest/reference/commands/'),
]


def fetch(name, url, refresh):
    path = os.path.join(CACHE, name + '.html')
    if refresh or not os.path.exists(path):
        os.makedirs(CACHE, exist_ok=True)
        req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0 (eq-autocomplete build script)'})
        with urllib.request.urlopen(req, timeout=60) as r:
            data = r.read().decode('utf-8')
        with open(path, 'w', encoding='utf-8') as f:
            f.write(data)
        print('downloaded', url)
    with open(path, encoding='utf-8') as f:
        return f.read()


def text_of(fragment):
    t = re.sub(r'<br\s*/?>', ' ', fragment)
    t = re.sub(r'<svg.*?</svg>', '', t, flags=re.S)
    t = re.sub(r'<[^>]+>', '', t)
    return re.sub(r'\s+', ' ', html.unescape(t)).strip()


# ---------------------------------------------------------------------------------------------
# Page -> list of (section, [syntax lines as token lists], description html)

BLOCK_RE = re.compile(r'<div class="language-eqcommand highlight"><pre><span></span><code>(.*?)</code></pre></div>', re.S)
SPAN_RE = re.compile(r'<span class="([^"]*)">(.*?)</span>', re.S)


def blocks(page, kind):
    """Yields (section, lines, dd_html). kind 'all' takes the plugin from <h2>, 'eq'/'mq' fix it."""
    heads = [(m.start(), text_of(m.group(1)).replace('¶', '').strip())
             for m in re.finditer(r'<h2 id="[^"]+">(.*?)</h2>', page, re.S)]
    found = list(BLOCK_RE.finditer(page))
    for i, m in enumerate(found):
        if kind == 'eq':
            section = 'EverQuest'
        elif kind == 'mq':
            section = 'MacroQuest'
        else:
            section = None
            for pos, name in heads:
                if pos < m.start():
                    section = name
            if section is None or section.startswith('Discussions'):
                continue
        nxt = found[i + 1].start() if i + 1 < len(found) else len(page)
        dd = re.search(r'<dd>(.*?)</dd>', page[m.end():nxt], re.S)
        lines = []
        for raw in m.group(1).split('\n'):
            toks = [(cls, html.unescape(t)) for cls, t in SPAN_RE.findall(raw)]
            if toks and toks[0][0] == 'nt':
                lines.append(toks)
        if lines:
            yield section, lines, (dd.group(1) if dd else '')


# ---------------------------------------------------------------------------------------------
# Syntax line -> grammar

WORD_RE = re.compile(r'^[-+]?[A-Za-z][A-Za-z0-9_\-+=.]*$')
RANGE_RE = re.compile(r'^\d+-\d+$')
# Words the docs highlight as literals but which stand for a value the user types.
PLACEHOLDER_WORDS = {
    'charname', 'channel', 'option', 'options', 'setting', 'settings', 'zonename', 'command', 'commands',
    'subindex', 'name', 'spellname', 'itemname', 'value', 'parameters', 'params', 'param', 'arguments',
    'args', 'text', 'message', 'zone', 'filename', 'playername',
}


def lex(toks):
    """Flattens highlighted tokens into ('{' '}' '[' ']' '<' '>' '|' '...' 'kw' 'var' 'q') items."""
    out = []
    for cls, t in toks:
        if cls == 'p':
            i = 0
            while i < len(t):
                if t.startswith('...', i):
                    out.append(('...', None)); i += 3
                elif t[i] in '{}[]<>|':
                    out.append((t[i], None)); i += 1
                elif t[i] == '"':
                    out.append(('q', None)); i += 1
                else:
                    i += 1
        elif cls.startswith('nv'):
            out.append(('var', t))
        elif cls in ('nl', 'no'):
            for w in t.split():
                if w == '...':
                    out.append(('...', None))
                elif w == '"':
                    out.append(('q', None))
                elif w.lower() in PLACEHOLDER_WORDS:
                    out.append(('var', w))
                elif w.lower() in ('//command', '/command'):
                    out.append(('var', 'command'))
                elif RANGE_RE.match(w):
                    out.append(('var', w))
                elif WORD_RE.match(w):
                    out.append(('kw', w))
                elif '/' in w and all(WORD_RE.match(p) for p in w.split('/')):
                    out.append(('kwalt', w.split('/')))
                elif '#' in w:
                    out.append(('var', w))
                # anything else (examples in quotes, punctuation, "(spell") is dropped
    return out


class Group:
    def __init__(self, opener):
        self.opener = opener  # '{', '[', or None for the line itself
        self.alts = [[]]

    @property
    def seq(self):
        return self.alts[-1]


def parse_line(toks):
    """Returns the grammar group for one syntax line (without its command word)."""
    items = lex(toks[1:])
    root = Group(None)
    stack = [root]
    i = 0
    while i < len(items):
        kind, val = items[i]
        top = stack[-1]
        if kind in ('{', '['):
            stack.append(Group(kind))
        elif kind in ('}', ']'):
            want = '{' if kind == '}' else '['
            if any(g.opener == want for g in stack[1:]):
                while True:
                    g = stack.pop()
                    stack[-1].seq.append(finish(g))
                    if g.opener == want:
                        break
            # an unmatched closer is ignored
        elif kind == '|':
            top.alts.append([])
        elif kind == '<':
            name, quoted = [], False
            j = i + 1
            while j < len(items) and items[j][0] != '>':
                k2, v2 = items[j]
                if k2 == 'var':
                    name.append(v2)
                elif k2 == 'q':
                    quoted = True
                elif k2 == 'kw':
                    name.append(v2)
                elif k2 == '|':
                    name.append('|')
                j += 1
            if name:
                top.seq.append(placeholder(' '.join(name), quoted))
            i = j  # skips the '>'
        elif kind == 'var':
            top.seq.append(placeholder(val, False))
        elif kind == 'kw':
            top.seq.append(val)
        elif kind == 'kwalt':
            top.seq.append({'alt': [[w] for w in val]})
        elif kind == '...':
            if top.seq:
                last = top.seq[-1]
                if isinstance(last, dict) and 'alt' in last:
                    last['r'] = 1
                else:
                    top.seq[-1] = {'alt': [[last]], 'r': 1}
        i += 1
    while len(stack) > 1:
        g = stack.pop()
        stack[-1].seq.append(finish(g))
    return root


def placeholder(name, quoted):
    name = re.sub(r'\s+', ' ', name.replace('"', '')).strip()
    node = {'v': name}
    if quoted:
        node['q'] = 1
    return node


def finish(group):
    alts = [a for a in group.alts]
    node = {'alt': alts}
    if group.opener == '[' or any(len(a) == 0 for a in alts):
        node['o'] = 1
        alts[:] = [a for a in alts if a]
        if not alts:
            alts.append([])
    return node


# ---------------------------------------------------------------------------------------------

ABBR_RE = re.compile(r'(?:[Cc]ommon(?:ly)? abbreviat\w*|[Ss]hort (?:version|form)|[Aa]lternat\w* commands?)\s*:?\s*([^.]*)')


def aliases_from(desc_html, cmd):
    found = []
    for m in ABBR_RE.finditer(text_of(desc_html)):
        for part in re.split(r',|\bor\b', m.group(1)):
            part = part.strip()
            if re.fullmatch(r'/[A-Za-z0-9_]+', part) and part.lower() != cmd:
                found.append(part.lower())
    return found


def description(desc_html):
    t = text_of(desc_html)
    t = re.sub(r'\s*Full documentation\s*$', '', t)
    if len(t) > 160:
        cut = t[:160]
        dot = cut.rfind('. ')
        t = cut[:dot + 1] if dot > 60 else cut.rstrip() + '...'
    return t


def lua_str(s):
    return '"' + s.replace('\\', '\\\\').replace('"', '\\"').replace('\n', ' ') + '"'


def lua_node(n):
    if isinstance(n, str):
        return lua_str(n)
    if 'v' in n:
        return '{v=' + lua_str(n['v']) + (',q=1' if n.get('q') else '') + '}'
    parts = ['alt={' + ','.join(lua_seq(a) for a in n['alt']) + '}']
    if n.get('o'):
        parts.append('o=1')
    if n.get('r'):
        parts.append('r=1')
    return '{' + ','.join(parts) + '}'


def lua_seq(seq):
    return '{' + ','.join(lua_node(n) for n in seq) + '}'


def main():
    refresh = '--refresh' in sys.argv
    cmds = {}
    order = [('all', 0), ('eq', 1), ('mq', 2)]
    for name, _ in order:
        url = dict(PAGES)[name]
        page = fetch(name, url, refresh)
        for section, lines, dd in blocks(page, name):
            for toks in lines:
                cmd = toks[0][1].strip().lower()
                if not re.fullmatch(r'/[a-z0-9_]+', cmd):
                    continue
                c = cmds.setdefault(cmd, {'plugin': section, 'desc': '', 'aliases': [], 'syntax': [], 'alts': []})
                if section in ('EverQuest',) and c['plugin'] != 'EverQuest':
                    c['plugin'] = 'EverQuest'  # EQ's own command, extended by a plugin: always there
                if not c['desc']:
                    c['desc'] = description(dd)
                for a in aliases_from(dd, cmd):
                    if a not in c['aliases']:
                        c['aliases'].append(a)
                syntax = ' '.join(t for _, t in toks)
                syntax = re.sub(r'\s+', ' ', syntax).strip()
                if syntax in c['syntax']:
                    continue
                c['syntax'].append(syntax)
                g = parse_line(toks)
                c['alts'].extend(a for a in g.alts)

    # A command's own name listed as another command's abbreviation would shadow it: drop those.
    for c in cmds.values():
        c['aliases'] = [a for a in c['aliases'] if a not in cmds]

    plugins = sorted({c['plugin'] for c in cmds.values()})
    today = datetime.date.today().isoformat()
    out = [
        '-- Generated by tools/build_commands.py from the RedGuides docs (%s). Do not edit by hand:' % today,
        '-- change the script, or put fixes in lib/extras.lua, then run: python tools/build_commands.py',
        '-- p = plugin (docs section), d = description, a = abbreviations, s = syntax as documented,',
        '-- g = grammar: alternatives, each a sequence of "keyword" | {v=placeholder, q=quoted} | {alt=..., o=optional, r=repeats}',
        'return {',
        '  generated = %s,' % lua_str(today),
        '  plugins = {' + ','.join(lua_str(p) for p in plugins) + '},',
        '  commands = {',
    ]
    for cmd in sorted(cmds):
        c = cmds[cmd]
        alts = [a for a in c['alts']]
        if not alts:
            alts = [[]]
        fields = [
            'p=' + lua_str(c['plugin']),
            'd=' + lua_str(c['desc']),
        ]
        if c['aliases']:
            fields.append('a={' + ','.join(lua_str(a) for a in c['aliases']) + '}')
        fields.append('s={' + ','.join(lua_str(s) for s in c['syntax']) + '}')
        fields.append('g={' + ','.join(lua_seq(a) for a in alts) + '}')
        out.append('    [%s]={%s},' % (lua_str(cmd), ','.join(fields)))
    out.append('  },')
    out.append('}')
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    with open(OUT, 'w', encoding='utf-8', newline='\n') as f:
        f.write('\n'.join(out) + '\n')
    print('wrote %s: %d commands from %d sections' % (os.path.relpath(OUT, REPO), len(cmds), len(plugins)))


if __name__ == '__main__':
    main()
