extends Node
## ゲームデータ：ドット絵・カード・敵・遺物・強化・遺志

var PAL := {
	"w": Color("#e8e0c8"), "g": Color("#9a927c"), "k": Color("#1a1420"), "r": Color("#ff3040"),
	"p": Color("#4a2a7a"), "P": Color("#b07cff"), "b": Color("#2c3550"), "B": Color("#4a5a80"),
	"s": Color("#b8c0cc"), "S": Color("#7a828e"), "y": Color("#e0b040"), "c": Color("#8a1c2c"),
	"C": Color("#c03040"), "f": Color("#c89070"), "F": Color("#8a5a48"), "h": Color("#6a4428"),
	"W": Color("#f4f4f4"), "l": Color("#6ad0ff"), "o": Color("#ff8a20"), "n": Color("#5c6248"),
	"N": Color("#3a3e2c"), "v": Color("#2a1840"), "e": Color("#7ab0ff"),
}

var SPR := {
	"skel": [
		"....wwww....",
		"...wwwwww...",
		"...wrwwrw...",
		"...wwwwww...",
		"....wkkw....",
		".....ww.....",
		"...wwwwww.s.",
		"..w.wggw.ws.",
		"..w.wwww.ws.",
		"..g.wggw..y.",
		".....ww.....",
		"....wggw....",
		"....w..w....",
		"....w..w....",
		"...ww..ww..."
	],
	"ghoul": [
		"...........nn.",
		"..........nnnn",
		"n........nnrnk",
		".nnnnnnnnnnnnw",
		"..nNnNnNnnnn..",
		"..nnnnnnnnnn..",
		"..nN.n....nN..",
		"..n..n....n.n.",
		"..w..w....w..w"
	],
	"archer": [
		"...pppppp...",
		"..pppppppp..",
		"..ppwwwwpp.h",
		"..pwrwwrwp.h",
		"..ppwkkwpp..h",
		"...pppppp...h",
		"..ppwwwwppwwh",
		".w.pwggwp...h",
		".w.pwwwwp...h",
		"...pwggwp..h.",
		"...pppppp.h..",
		"...pp..pp....",
		"....w..w.....",
		"....w..w.....",
		"...ww..ww...."
	],
	"knight": [
		".....bbbb.....",
		"....bBBBBb....",
		"....bBkkBb....",
		"....bkrrkb....",
		"....bBBBBb....",
		".....bbbb.....",
		"..bbbbbbbbbb..",
		".bBBbBBBBbBBb.",
		".bBBbBccBbBBbs",
		".bbbbBccBbbbbs",
		"..k.bBBBBb..ks",
		"..k.bbbbbb..ks",
		"..k.bBBBBb..ky",
		".....bccb.....",
		"....bb..bb....",
		"....bb..bb....",
		"....bb..bb....",
		"...bbb..bbb..."
	],
	"wraith": [
		"....PPPP....",
		"...PPPPPP...",
		"..PPkPPkPP..",
		"..PPlPPlPP..",
		"..PPPPPPPP..",
		"...PPkkPP...",
		".PPPPPPPPPP.",
		"P.PPPPPPPP.P",
		"P..PPPPPP..P",
		"...PPPPPP...",
		"....PPPPp...",
		"....pPPp....",
		".....pPp....",
		"......pp....",
		".......p...."
	],
	"witch": [
		".....cc.....",
		"....cccc....",
		"...cccccc...",
		"..cccccccc..",
		".cccccccccc.",
		"...ffffff..r",
		"...fkffkf..o",
		"...ffffff..h",
		"....ffff...h",
		"...cCCCCc..h",
		"..cccCCcccfh",
		"..f.cCCc...h",
		"....cCCc...h",
		"...cccccc...",
		"..cccccccc..",
		"..kk....kk.."
	],
	"golem": [
		"......ffff......",
		".....ffffff.....",
		".....frffrf.....",
		".....ffkkff.....",
		"...ffffffffff...",
		"..ffffkFffffff..",
		".fffffkfffFffff.",
		".fffFffffkffffff",
		".fff.ffffkfff.ff",
		".fff.fFffffff.ff",
		".fff.fffffkff.ff",
		".FFF.ffffkfFf.FF",
		".....ffffffff...",
		".....fff..fff...",
		".....fFf..fFf...",
		".....fff..fff...",
		"....ffff..ffff..",
		"....hhhh..hhhh.."
	],
	"dragon": [
		"....g...............ww..",
		"...gwg.............wwww.",
		"..gwwwg...........wwrww.",
		".gwwwwwg.........wwwwwwk",
		"gwwgwwwwg...wwwwwwwkwwk.",
		"....wwwwwwwwwwwwwww.kkk.",
		".....wwgwgwgwgwwww......",
		"......wwwwwwwwwww.......",
		".....wwgwgwgwgwww.......",
		"...gww.ww....ww.ww......",
		"..gw...ww....ww..w......",
		"..w....ww....ww.........",
		"......www...www........."
	],
	"foot": [
		"....ssss....",
		"...ssssss...",
		"...sskkss...",
		"...sffffs...",
		"....ffff....",
		"...WWWWWW...",
		"..sWWyyWWs.s",
		"..fWyyyyWfs.",
		"..fWWyyWWfs.",
		"...WWWWWW.h.",
		"...hhhhhh...",
		"....h..h....",
		"....h..h....",
		"...kk..kk..."
	],
	"spear": [
		"....ssss.....s",
		"...ssssss...ss",
		"...sskkss..h..",
		"...sffffs.h...",
		"....ffff.h....",
		"...WWWWWh.....",
		"..sWWyyhWs....",
		"..fWyyhyWf....",
		"..fWWhyWWf....",
		"...WhWWWW.....",
		"...hhhhhh.....",
		"..h.h..h......",
		"....h..h......",
		"...kk..kk....."
	],
	"xbow": [
		"....hhhh....",
		"...hhhhhh...",
		"...hffffh...",
		"...fkffkf...",
		"....ffff....",
		"...WWWWWW...",
		"..fWWyyWWhhh",
		"..fWyyyyhshh",
		"...WWyyWWhhh",
		"...WWWWWW...",
		"...hhhhhh...",
		"....h..h....",
		"....h..h....",
		"...kk..kk..."
	],
	"paladin": [
		".....yyyy.....",
		"....ssssss....",
		"....sskkss....",
		"....ssllss....",
		"....ssssss....",
		"..y..ssss.....",
		".yyysssssss...",
		".yWysWWyWWss.s",
		".yWysWyyyWss.s",
		".yyysWWyWWss.s",
		"..y.sWWWWWs..y",
		"....ssssss...y",
		"....sWWWWs....",
		"....ss..ss....",
		"....ss..ss....",
		"....ss..ss....",
		"...sss..sss..."
	],
	"priest": [
		"....WWWW....",
		"...WWyyWW...",
		"...WffffW...",
		"...fkffkf...",
		"....ffff..y.",
		"...WWWWWWyyy",
		"..WWWyyWWWy.",
		"..fWyyyyWWh.",
		"...WWyyWWWh.",
		"...WWWWWW.h.",
		"..WWWWWWWWh.",
		"..WWWWWWWW..",
		"...kk..kk..."
	],
	"inq": [
		"....kkkk....",
		"...kkkkkk...",
		"..kkkkkkkk..",
		"...kffffk...",
		"...frffrf...",
		"...kkkkkk...",
		"..kkcyyckk.s",
		"..fkcyyckfs.",
		"...kcyyck.s.",
		"...kkkkkk...",
		"...kk..kk...",
		"...kk..kk...",
		"..kkk..kkk.."
	],
	"seraph": [
		"WW..........yyyy........",
		"WWW........yeeeey.......",
		".WWW........yyyy........",
		".WWWW.......ffff........",
		"..WWWW.....fkffkf.......",
		"..WWWWW.....ffff....yyy.",
		"...WWWWW..WWWWWWWW.yWWy.",
		"...WWWWWWWWWyyyyWWWWyy..",
		"....WWWWWWWWWyyWWWWWy...",
		"....WWWWWWWWWyyWWWW.s...",
		".....WWW...WWWWWWWW.s...",
		"...........WWWWWWWW.s...",
		"..........WWWWWWWWWWs...",
		".........WWWWWWWWWWWWs..",
		"..........yy......yy...."
	],
}

# 亡者軍のカード
var CARDS := {
	"skel":   {"name": "骸骨兵",   "spr": "skel",   "cost": 50,  "cd": 2.0,  "hp": 120,  "atk": 18,  "range": 22,  "spd": 42, "rate": 0.9,  "kb": 2, "desc": "安価な前衛。数で押す。"},
	"ghoul":  {"name": "屍狼",     "spr": "ghoul",  "cost": 75,  "cd": 3.0,  "hp": 90,   "atk": 13,  "range": 18,  "spd": 90, "rate": 0.45, "kb": 2, "desc": "俊足の連撃。"},
	"archer": {"name": "骨弓手",   "spr": "archer", "cost": 120, "cd": 5.0,  "hp": 70,   "atk": 24,  "range": 150, "spd": 32, "rate": 1.4,  "kb": 1, "proj": Color("#d8d0b0"), "desc": "後方から射撃。"},
	"knight": {"name": "死霊騎士", "spr": "knight", "cost": 240, "cd": 9.0,  "hp": 700,  "atk": 34,  "range": 26,  "spd": 26, "rate": 1.3,  "kb": 3, "desc": "重装の壁役。"},
	"wraith": {"name": "怨霊",     "spr": "wraith", "cost": 200, "cd": 8.0,  "hp": 110,  "atk": 30,  "range": 115, "spd": 46, "rate": 1.6,  "kb": 1, "aoe": 30, "proj": Color("#b07cff"), "fly": true, "desc": "呪弾で小範囲攻撃。"},
	"witch":  {"name": "血の魔女", "spr": "witch",  "cost": 320, "cd": 12.0, "hp": 160,  "atk": 55,  "range": 155, "spd": 30, "rate": 2.2,  "kb": 1, "aoe": 55, "proj": Color("#ff3040"), "desc": "血の爆炎で範囲攻撃。"},
	"golem":  {"name": "屍肉巨人", "spr": "golem",  "cost": 420, "cd": 16.0, "hp": 1900, "atk": 62,  "range": 32,  "spd": 18, "rate": 2.0,  "kb": 4, "aoe": 35, "desc": "巨体で薙ぎ払う。"},
	"dragon": {"name": "骨竜",     "spr": "dragon", "cost": 800, "cd": 35.0, "hp": 2800, "atk": 150, "range": 125, "spd": 22, "rate": 2.6,  "kb": 5, "aoe": 75, "proj": Color("#7affb0"), "desc": "冥府の息吹。最強の切り札。"},
}
var STARTER := ["skel", "ghoul", "archer"]

# 白銀教団
var ENEMIES := {
	"foot":    {"name": "見習い兵", "spr": "foot",    "hp": 80,   "atk": 10, "range": 20,  "spd": 38, "rate": 1.0, "kb": 1, "soul": 4},
	"spear":   {"name": "槍兵",     "spr": "spear",   "hp": 130,  "atk": 16, "range": 34,  "spd": 34, "rate": 1.1, "kb": 2, "soul": 6},
	"xbow":    {"name": "弩兵",     "spr": "xbow",    "hp": 70,   "atk": 20, "range": 135, "spd": 30, "rate": 1.7, "kb": 1, "proj": Color("#c0a070"), "soul": 7},
	"priest":  {"name": "神官",     "spr": "priest",  "hp": 120,  "atk": 8,  "range": 110, "spd": 28, "rate": 1.8, "kb": 1, "heal": 28, "soul": 9},
	"paladin": {"name": "聖騎士",   "spr": "paladin", "hp": 650,  "atk": 30, "range": 26,  "spd": 24, "rate": 1.3, "kb": 3, "soul": 16},
	"inq":     {"name": "審問官",   "spr": "inq",     "hp": 280,  "atk": 48, "range": 24,  "spd": 62, "rate": 0.9, "kb": 2, "soul": 14},
	"seraph":  {"name": "熾天使",   "spr": "seraph",  "hp": 2200, "atk": 70, "range": 70,  "spd": 16, "rate": 2.4, "kb": 6, "aoe": 40, "proj": Color("#fff0a0"), "soul": 120, "boss": true, "fly": true},
}

var RELICS := {
	"crown":  {"name": "呪われた冠",   "desc": "全ユニット攻撃力 +15%"},
	"grail":  {"name": "黒血の聖杯",   "desc": "魂力の回復速度 +15%"},
	"bell":   {"name": "葬送の鐘",     "desc": "冥王の裁きのチャージ時間 -20%"},
	"shield": {"name": "骨の大盾",     "desc": "玉座の耐久 +25%"},
	"march":  {"name": "亡者の行進曲", "desc": "ユニット移動速度 +12%"},
	"eater":  {"name": "魂喰らい",     "desc": "敵撃破で魂力 +8"},
	"hide":   {"name": "死皮の外套",   "desc": "全ユニット体力 +15%"},
	"hourg":  {"name": "黒砂の時計",   "desc": "召喚クールダウン -12%"},
}

var UPS := {
	"regen":  {"name": "魂力の泉", "desc": "魂力の回復 +10%/Lv", "base": 40, "g": 1.5},
	"maxm":   {"name": "魂の器",   "desc": "魂力の上限 +120/Lv", "base": 30, "g": 1.45},
	"castle": {"name": "骨の玉座", "desc": "玉座の耐久 +20%/Lv", "base": 35, "g": 1.45},
	"wallet": {"name": "墓荒らし", "desc": "獲得魂貨 +10%/Lv",   "base": 60, "g": 1.6},
}

# パッシブスキル（冥核で解放する永続強化。転生しても失われない）
# branch: 系統, tier: 段階(1〜3), max: 最大Lv, base: 基本コスト（Lv×base 冥核）
# req: 解放条件 [スキルID, 必要Lv]
var BRANCHES := [["army", "軍勢の業"], ["throne", "玉座の業"], ["sorcery", "冥術の業"]]
var PASSIVES := {
	"might":   {"branch": "army", "tier": 1, "max": 10, "base": 1, "name": "冥王の威光", "desc": "全ユニット攻撃力 +12%/Lv（乗算）"},
	"flesh":   {"branch": "army", "tier": 1, "max": 10, "base": 1, "name": "不死の肉体", "desc": "全ユニット体力 +12%/Lv（乗算）"},
	"regen":   {"branch": "army", "tier": 2, "max": 3,  "base": 3, "req": ["flesh", 2], "name": "骨の再生", "desc": "味方ユニットが毎秒 最大体力の1.5%/Lv 回復"},
	"drain":   {"branch": "army", "tier": 2, "max": 3,  "base": 3, "req": ["might", 2], "name": "魂吸い", "desc": "与えたダメージの10%/Lv 体力を吸収"},
	"undying": {"branch": "army", "tier": 3, "max": 1,  "base": 8, "req": ["regen", 1], "name": "不死の執念", "desc": "味方は一度だけ致命傷を体力1で耐える"},
	"legion":  {"branch": "army", "tier": 3, "max": 3,  "base": 6, "req": ["drain", 1], "name": "死者の行進", "desc": "一定時間ごとに骸骨兵を無償で召喚（14/10/7秒）"},
	"start":   {"branch": "throne", "tier": 1, "max": 5,  "base": 1, "name": "冥府の蓄え", "desc": "開始時の魂力 +60/Lv"},
	"flow":    {"branch": "throne", "tier": 1, "max": 10, "base": 1, "name": "冥河の流れ", "desc": "魂力の回復 +10%/Lv"},
	"cannon":  {"branch": "throne", "tier": 2, "max": 5,  "base": 3, "req": ["start", 1], "name": "玉座の呪砲", "desc": "玉座が近づく敵を自動で砲撃（威力 Lvに比例）"},
	"miasma":  {"branch": "throne", "tier": 2, "max": 3,  "base": 3, "req": ["flow", 2], "name": "瘴気の結界", "desc": "玉座付近の敵の移動速度 -20%/Lv"},
	"rite":    {"branch": "throne", "tier": 3, "max": 3,  "base": 6, "req": ["miasma", 1], "name": "黒き儀式", "desc": "召喚クールダウン -12%/Lv"},
	"fortress":{"branch": "throne", "tier": 3, "max": 3,  "base": 6, "req": ["cannon", 2], "name": "骨の城塞", "desc": "玉座の耐久 +40%/Lv、玉座が受けるダメージ -10%/Lv"},
	"harvest": {"branch": "sorcery", "tier": 1, "max": 10, "base": 1, "name": "魂の収穫", "desc": "獲得魂貨 +25%/Lv"},
	"wrath":   {"branch": "sorcery", "tier": 1, "max": 5,  "base": 1, "name": "冥王の怒り", "desc": "冥王の裁きの威力 +30%/Lv"},
	"chant":   {"branch": "sorcery", "tier": 2, "max": 3,  "base": 3, "req": ["wrath", 1], "name": "速唱", "desc": "冥王の裁きのチャージ時間 -15%/Lv"},
	"hex":     {"branch": "sorcery", "tier": 2, "max": 3,  "base": 3, "req": ["harvest", 1], "name": "弱体の呪詛", "desc": "敵の攻撃力 -7%/Lv"},
	"doom":    {"branch": "sorcery", "tier": 3, "max": 1,  "base": 8, "req": ["chant", 1], "name": "終焉の刻", "desc": "冥王の裁きが敵を吹き飛ばし、敵の砦にも直撃する"},
	"pact":    {"branch": "sorcery", "tier": 3, "max": 5,  "base": 6, "req": ["hex", 1], "name": "古の盟約", "desc": "転生後、追加カードを1枚所持して開始/Lv"},
}

## スプライトキー -> {"r": 右向き, "l": 左向き}
var TEX := {}

func _ready() -> void:
	for k in SPR:
		TEX[k] = {"r": make_tex(SPR[k], 4, false), "l": make_tex(SPR[k], 4, true)}

func make_tex(rows: Array, px: int, flip: bool) -> ImageTexture:
	var w := 0
	for r in rows:
		w = max(w, (r as String).length())
	var h := rows.size()
	var img := Image.create(w * px, h * px, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for j in h:
		var r: String = rows[j]
		for i in r.length():
			var ch := r[i]
			if ch == "." or not PAL.has(ch):
				continue
			var ii := (w - 1 - i) if flip else i
			img.fill_rect(Rect2i(ii * px, j * px, px, px), PAL[ch])
	return ImageTexture.create_from_image(img)
