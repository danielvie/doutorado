import math, json

# ---------------- linear system  xdot = A x,  A = [[0,1],[-2,-3]] ----------------
A = [[0.0, 1.0], [-2.0, -3.0]]
P = [[1.25, 0.25], [0.25, 0.25]]

def V(x):
    return P[0][0]*x[0]*x[0] + 2*P[0][1]*x[0]*x[1] + P[1][1]*x[1]*x[1]

def Vdot(x):
    return -(x[0]**2 + x[1]**2)

def f(x):
    return (A[0][0]*x[0]+A[0][1]*x[1], A[1][0]*x[0]+A[1][1]*x[1])

def exact(x0, t):
    a, b = x0
    c1 = 2*a + b          # eigvec (1,-1), lambda = -1
    c2 = -(a + b)         # eigvec (1,-2), lambda = -2
    e1, e2 = math.exp(-t), math.exp(-2*t)
    return (c1*e1 + c2*e2, -c1*e1 - 2*c2*e2)

# verify Lyapunov equation A^T P + P A = -I
def matmul(M, N):
    return [[sum(M[i][k]*N[k][j] for k in range(2)) for j in range(2)] for i in range(2)]
AT = [[A[j][i] for j in range(2)] for i in range(2)]
S = matmul(AT, P)
PA = matmul(P, A)
res = [[S[i][j]+PA[i][j] for j in range(2)] for i in range(2)]
print("A^T P + P A =", res)
print("P eigs:", [(1.5 + s*math.sqrt(1.5**2 - 4*0.25))/2 for s in (1, -1)])

# ---------------- generic plotting helpers ----------------
class Frame:
    def __init__(self, x0, x1, y0, y1, px, py, pw, ph):
        self.x0, self.x1, self.y0, self.y1 = x0, x1, y0, y1
        self.px, self.py, self.pw, self.ph = px, py, pw, ph
    def X(self, x): return self.px + (x - self.x0)/(self.x1 - self.x0)*self.pw
    def Y(self, y): return self.py + self.ph - (y - self.y0)/(self.y1 - self.y0)*self.ph

def path(fr, pts, close=False):
    d = []
    for i, (x, y) in enumerate(pts):
        d.append(("M" if i == 0 else "L") + "%.2f %.2f" % (fr.X(x), fr.Y(y)))
    if close: d.append("Z")
    return "".join(d)

out = {}

# ---------------- CHART: phase plane with V level sets ----------------
R = 2.6
fr = Frame(-R, R, -R, R, 60, 30, 460, 460)

def ellipse_pts(c, n=240):
    pts = []
    for i in range(n+1):
        th = 2*math.pi*i/n
        u = (math.cos(th), math.sin(th))
        q = P[0][0]*u[0]**2 + 2*P[0][1]*u[0]*u[1] + P[1][1]*u[1]**2
        r = math.sqrt(c/q)
        pts.append((r*u[0], r*u[1]))
    return pts

out["ELLIPSES"] = "".join(
    '<path class="lev" d="%s"/>' % path(fr, ellipse_pts(c), True) for c in (0.05, 0.2, 0.5))
out["ELLIPSE_MAIN"] = '<path class="lev main" d="%s"/>' % path(fr, ellipse_pts(1.25), True)

def rk4(x, h, n, g):
    pts = [x]
    for _ in range(n):
        k1 = g(x); k2 = g((x[0]+h/2*k1[0], x[1]+h/2*k1[1]))
        k3 = g((x[0]+h/2*k2[0], x[1]+h/2*k2[1])); k4 = g((x[0]+h*k3[0], x[1]+h*k3[1]))
        x = (x[0]+h/6*(k1[0]+2*k2[0]+2*k3[0]+k4[0]), x[1]+h/6*(k1[1]+2*k2[1]+2*k3[1]+k4[1]))
        pts.append(x)
    return pts

# eight trajectories launched from the V = 1.25 level set
starts = []
n0 = 8
for i in range(n0):
    th = 2*math.pi*i/n0 + 0.35
    u = (math.cos(th), math.sin(th))
    q = P[0][0]*u[0]**2 + 2*P[0][1]*u[0]*u[1] + P[1][1]*u[1]**2
    r = math.sqrt(1.25/q)
    starts.append((r*u[0], r*u[1]))
trajs = []
for s in starts:
    pts = [exact(s, t*0.02) for t in range(301)]
    trajs.append('<path class="traj" d="%s"/>' % path(fr, pts))
out["TRAJS"] = "".join(trajs)
out["DOTS"] = "".join('<circle class="ic" cx="%.2f" cy="%.2f" r="3.4"/>' % (fr.X(s[0]), fr.Y(s[1])) for s in starts)

# highlighted trajectory from (1,0)
hi = [exact((1.0, 0.0), t*0.01) for t in range(601)]
out["TRAJ_HI"] = '<path class="traj hi" d="%s"/>' % path(fr, hi)
out["IC_HI"] = '<circle class="ic hi" cx="%.2f" cy="%.2f" r="5"/>' % (fr.X(1.0), fr.Y(0.0))

# vector field
arrows = []
g = [-2.0, -1.0, 0.0, 1.0, 2.0]
for xa in g:
    for xb in g:
        if abs(xa) < 1e-9 and abs(xb) < 1e-9: continue
        vx, vy = f((xa, xb))
        m = math.hypot(vx, vy)
        if m < 1e-9: continue
        L = 0.30
        ux, uy = vx/m*L, vy/m*L
        x1p, y1p = fr.X(xa-ux/2), fr.Y(xb-uy/2)
        x2p, y2p = fr.X(xa+ux/2), fr.Y(xb+uy/2)
        arrows.append('<line class="fld" x1="%.2f" y1="%.2f" x2="%.2f" y2="%.2f" marker-end="url(#ah)"/>' % (x1p, y1p, x2p, y2p))
out["FIELD"] = "".join(arrows)

# axis ticks for the phase plane
tk = []
for v in (-2, -1, 1, 2):
    tk.append('<line class="tick" x1="%.2f" y1="%.2f" x2="%.2f" y2="%.2f"/>' % (fr.X(v), fr.Y(0)-4, fr.X(v), fr.Y(0)+4))
    tk.append('<text class="tl" x="%.2f" y="%.2f" text-anchor="middle">%d</text>' % (fr.X(v), fr.Y(0)+18, v))
    tk.append('<line class="tick" x1="%.2f" y1="%.2f" x2="%.2f" y2="%.2f"/>' % (fr.X(0)-4, fr.Y(v), fr.X(0)+4, fr.Y(v)))
    tk.append('<text class="tl" x="%.2f" y="%.2f" text-anchor="end">%d</text>' % (fr.X(0)-9, fr.Y(v)+4, v))
out["PHASE_AXES"] = "".join(tk)
out["PHASE_BOX"] = "%.2f %.2f %.2f %.2f" % (fr.px, fr.py, fr.pw, fr.ph)
out["PHASE_X0"] = "%.2f" % fr.X(0); out["PHASE_Y0"] = "%.2f" % fr.Y(0)

# ---------------- CHART: V(t) and Vdot(t) ----------------
T = 4.0
f2 = Frame(0, T, -1.4, 1.4, 62, 24, 560, 300)
vs, vds = [], []
for i in range(401):
    t = T*i/400
    x = exact((1.0, 0.0), t)
    vs.append((t, V(x))); vds.append((t, Vdot(x)))
out["VT"] = path(f2, vs)
out["VDT"] = path(f2, vds)
out["VT_FILL"] = path(f2, vs + [(T, 0.0), (0.0, 0.0)], True)
gl = []
for v in (-1.0, -0.5, 0.5, 1.0):
    gl.append('<line class="grid" x1="%.2f" y1="%.2f" x2="%.2f" y2="%.2f"/>' % (f2.X(0), f2.Y(v), f2.X(T), f2.Y(v)))
    gl.append('<text class="tl" x="%.2f" y="%.2f" text-anchor="end">%.1f</text>' % (f2.X(0)-8, f2.Y(v)+4, v))
for t in (1, 2, 3, 4):
    gl.append('<text class="tl" x="%.2f" y="%.2f" text-anchor="middle">%d</text>' % (f2.X(t), f2.Y(-1.4)+20, t))
    gl.append('<line class="tick" x1="%.2f" y1="%.2f" x2="%.2f" y2="%.2f"/>' % (f2.X(t), f2.Y(-1.4), f2.X(t), f2.Y(-1.4)+5))
out["VT_GRID"] = "".join(gl)
out["VT_ZERO"] = "%.2f" % f2.Y(0.0)
out["VT_L"] = "%.2f" % f2.X(0); out["VT_R"] = "%.2f" % f2.X(T)
out["VT_TOP"] = "%.2f" % f2.Y(1.4); out["VT_BOT"] = "%.2f" % f2.Y(-1.4)

# ---------------- table of numbers ----------------
rows = []
for i in range(13):
    t = 0.25*i
    x = exact((1.0, 0.0), t)
    rows.append((t, x[0], x[1], V(x), Vdot(x)))
out["TABLE"] = "".join(
    "<tr><td>%.2f</td><td>%+.4f</td><td>%+.4f</td><td>%.4f</td><td>%+.4f</td></tr>" % r for r in rows)
for r in rows[:6]: print(r)

# ---------------- CHART: the wrong candidate W = x1^2 + x2^2 ----------------
best, bphi = -1, 0
for i in range(2000):
    phi = 2*math.pi*i/2000
    x = (math.cos(phi), math.sin(phi))
    w = -2*x[0]*x[1] - 6*x[1]**2
    if w > best: best, bphi = w, phi
x0b = (math.cos(bphi), math.sin(bphi))
print("worst IC for W:", x0b, "Wdot0 =", best)

# panel A: the derivatives themselves — the sign is what the theorem tests
def Wdot(x): return -2*x[0]*x[1] - 6*x[1]**2
TA = 1.5
dw = [(TA*i/400, Wdot(exact(x0b, TA*i/400))) for i in range(401)]
dv = [(TA*i/400, Vdot(exact(x0b, TA*i/400))) for i in range(401)]
print("Wdot range", min(w for _, w in dw), max(w for _, w in dw))
print("Vdot range", min(w for _, w in dv), max(w for _, w in dv))
zc = [t for (t, w), (t2, w2) in zip(dw, dw[1:]) if w > 0 >= w2]
print("Wdot crosses zero at t =", zc)
fa = Frame(0, TA, -1.25, 0.30, 56, 26, 300, 250)
out["DW"] = path(fa, dw)
out["DV"] = path(fa, dv)
out["DW_POS"] = path(fa, [(t, w) for t, w in dw if w >= 0] + [(zc[0], 0.0), (0.0, 0.0)], True)
ga = []
for v in (-1.0, -0.5, 0.0):
    ga.append('<line class="grid" x1="%.2f" y1="%.2f" x2="%.2f" y2="%.2f"/>' % (fa.X(0), fa.Y(v), fa.X(TA), fa.Y(v)))
    ga.append('<text class="tl" x="%.2f" y="%.2f" text-anchor="end">%.1f</text>' % (fa.X(0)-7, fa.Y(v)+4, v))
for t in (0.5, 1.0, 1.5):
    ga.append('<text class="tl" x="%.2f" y="%.2f" text-anchor="middle">%.1f</text>' % (fa.X(t), fa.Y(-1.25)+18, t))
out["DGRID"] = "".join(ga)
out["DZERO"] = "%.2f" % fa.Y(0.0)
out["DL"] = "%.2f" % fa.X(0); out["DR"] = "%.2f" % fa.X(TA)
out["DTOP"] = "%.2f" % fa.Y(0.30); out["DBOT"] = "%.2f" % fa.Y(-1.25)
out["DWD0X"] = "%.2f" % fa.X(0); out["DWD0Y"] = "%.2f" % fa.Y(Wdot(x0b))
out["DVD0X"] = "%.2f" % fa.X(0); out["DVD0Y"] = "%.2f" % fa.Y(Vdot(x0b))
out["DZX"] = "%.2f" % fa.X(zc[0]); out["DZT"] = "%.2f" % zc[0]

# panel B: the resulting bump in W itself
TB = 0.4
W0 = x0b[0]**2 + x0b[1]**2
ws = [(TB*i/400, (lambda x: (x[0]**2 + x[1]**2)/W0)(exact(x0b, TB*i/400))) for i in range(401)]
wmax = max(w for _, w in ws); wmaxt = [t for t, w in ws if w == wmax][0]
print("W/W0 peak %.5f at t=%.3f ; at t=%.1f -> %.4f" % (wmax, wmaxt, TB, ws[-1][1]))
fb = Frame(0, TB, 0.985, 1.018, 452, 26, 168, 250)
out["WB"] = path(fb, ws)
out["WB_FILL"] = path(fb, [(t, max(w, 1.0)) for t, w in ws if w >= 1.0] + [(0.0, 1.0)], True)
gb = []
for v in (0.99, 1.00, 1.01):
    gb.append('<line class="grid%s" x1="%.2f" y1="%.2f" x2="%.2f" y2="%.2f"/>' % (
        " one" if v == 1.0 else "", fb.X(0), fb.Y(v), fb.X(TB), fb.Y(v)))
    gb.append('<text class="tl" x="%.2f" y="%.2f" text-anchor="end">%.2f</text>' % (fb.X(0)-7, fb.Y(v)+4, v))
for t in (0.2, 0.4):
    gb.append('<text class="tl" x="%.2f" y="%.2f" text-anchor="middle">%.1f</text>' % (fb.X(t), fb.Y(0.985)+18, t))
out["WBGRID"] = "".join(gb)
out["WBL"] = "%.2f" % fb.X(0); out["WBR"] = "%.2f" % fb.X(TB)
out["WBTOP"] = "%.2f" % fb.Y(1.018); out["WBBOT"] = "%.2f" % fb.Y(0.985)
out["WB_PEAK"] = '<circle class="pk" cx="%.2f" cy="%.2f" r="4"/>' % (fb.X(wmaxt), fb.Y(wmax))
out["W_PEAK_VAL"] = "%.4f" % wmax; out["W_PEAK_T"] = "%.2f" % wmaxt
out["W_IC"] = "(%.3f,\u2009%.3f)" % x0b
out["W_DOT0"] = "%.3f" % best

# ---------------- pendulum:  th'' + b th' + (g/L) sin th = 0 ----------------
bb, w2 = 0.5, 9.81
def fp(s):
    return (s[1], -bb*s[1] - w2*math.sin(s[0]))
def E(s):
    return 0.5*s[1]**2 + w2*(1 - math.cos(s[0]))

s = (2.2, 0.0)
h = 0.002
P_ = [s]
for i in range(6000):
    x = P_[-1]
    k1 = fp(x); k2 = fp((x[0]+h/2*k1[0], x[1]+h/2*k1[1]))
    k3 = fp((x[0]+h/2*k2[0], x[1]+h/2*k2[1])); k4 = fp((x[0]+h*k3[0], x[1]+h*k3[1]))
    P_.append((x[0]+h/6*(k1[0]+2*k2[0]+2*k3[0]+k4[0]), x[1]+h/6*(k1[1]+2*k2[1]+2*k3[1]+k4[1])))
f4 = Frame(-2.8, 2.8, -6.5, 6.5, 55, 25, 400, 330)
out["PEND_PHASE"] = path(f4, P_[::4])
out["PEND_IC"] = '<circle class="ic hi" cx="%.2f" cy="%.2f" r="5"/>' % (f4.X(2.2), f4.Y(0.0))
out["PEND_ORIGIN"] = '<circle class="eq" cx="%.2f" cy="%.2f" r="4"/>' % (f4.X(0), f4.Y(0))
out["PEND_ZEROLINE"] = '<line class="zeroset" x1="%.2f" y1="%.2f" x2="%.2f" y2="%.2f"/>' % (f4.X(-2.8), f4.Y(0), f4.X(2.8), f4.Y(0))
pt = []
for v in (-2, -1, 1, 2):
    pt.append('<text class="tl" x="%.2f" y="%.2f" text-anchor="middle">%d</text>' % (f4.X(v), f4.Y(-6.5)+20, v))
for v in (-6, -3, 3, 6):
    pt.append('<line class="grid" x1="%.2f" y1="%.2f" x2="%.2f" y2="%.2f"/>' % (f4.X(-2.8), f4.Y(v), f4.X(2.8), f4.Y(v)))
    pt.append('<text class="tl" x="%.2f" y="%.2f" text-anchor="end">%d</text>' % (f4.X(-2.8)-8, f4.Y(v)+4, v))
out["PEND_GRID"] = "".join(pt)
out["PEND_BOX"] = "%.2f %.2f %.2f %.2f" % (f4.px, f4.py, f4.pw, f4.ph)

Emax = E((2.2, 0.0))
f5 = Frame(0, 12, 0, Emax*1.05, 55, 25, 400, 330)
es = [(i*h, E(P_[i])) for i in range(0, 6001, 4)]
out["PEND_E"] = path(f5, es)
eg = []
for v in (4, 8, 12, 16):
    eg.append('<line class="grid" x1="%.2f" y1="%.2f" x2="%.2f" y2="%.2f"/>' % (f5.X(0), f5.Y(v), f5.X(12), f5.Y(v)))
    eg.append('<text class="tl" x="%.2f" y="%.2f" text-anchor="end">%d</text>' % (f5.X(0)-8, f5.Y(v)+4, v))
for t in (3, 6, 9, 12):
    eg.append('<text class="tl" x="%.2f" y="%.2f" text-anchor="middle">%d</text>' % (f5.X(t), f5.Y(0)+20, t))
out["PEND_EGRID"] = "".join(eg)
out["PEND_EBOX"] = "%.2f %.2f %.2f %.2f" % (f5.px, f5.py, f5.pw, f5.ph)
print("E0 =", Emax, "E(12) =", es[-1][1])

with open("frag.json", "w") as fh:
    json.dump(out, fh)
print("fragments:", len(out))

# ================= schematic diagrams =================
sch = {}

def spiral(cx, cy, r0, r1, turns, n=400, start=0.0):
    pts = []
    for i in range(n+1):
        u = i/n
        th = start + 2*math.pi*turns*u
        r = r0 + (r1-r0)*u
        pts.append("%s%.2f %.2f" % ("M" if i == 0 else "L", cx + r*math.cos(th), cy + r*math.sin(th)*0.92))
    return "".join(pts)

# panel 1: stable but not asymptotically (closed orbit, wobbling)
pts = []
for i in range(481):
    th = 2*math.pi*i/120
    r = 34 + 6*math.sin(3*th)
    pts.append("%s%.2f %.2f" % ("M" if i == 0 else "L", 100 + r*math.cos(th), 100 + r*math.sin(th)))
sch["EPS_A"] = "".join(pts)
sch["EPS_B"] = spiral(100, 100, 34, 1.5, 3.4)
sch["EPS_C"] = spiral(100, 100, 16, 78, 2.6)

# nested level sets for the bowl figure (perspective rings)
rings = []
for k, r in enumerate((22, 44, 66, 88)):
    rings.append('<ellipse class="ring r%d" cx="150" cy="%d" rx="%d" ry="%d"/>' % (k, 118 - k*17, r, int(r*0.34)))
sch["BOWL_RINGS"] = "".join(rings)
# ball rolling down the inside of the bowl
sch["BOWL_TRAJ"] = spiral(150, 118, 84, 3, 2.2, start=math.pi*0.15)

# gradient / velocity geometry: level set, tangent, an inward velocity, and the angle arc
cx, cy, rx, ry = 215, 160, 130, 88
th = 2.35
px_, py_ = cx + rx*math.cos(th), cy + ry*math.sin(th)
gx, gy = math.cos(th)/rx, math.sin(th)/ry
gm = math.hypot(gx, gy); gux, guy = gx/gm, gy/gm            # outward unit normal (uphill)
tx, ty = -rx*math.sin(th), ry*math.cos(th)
tm = math.hypot(tx, ty); tux, tuy = -tx/tm, -ty/tm          # unit tangent
vux, vuy = -0.80*gux + 0.62*tux, -0.80*guy + 0.62*tuy       # an inward-pointing velocity
vm = math.hypot(vux, vuy); vux, vuy = vux/vm, vuy/vm
L = 66
sch["GEO_PTX"] = "%.2f" % px_;                 sch["GEO_PTY"] = "%.2f" % py_
sch["GEO_GRADX"] = "%.2f" % (px_+gux*L);       sch["GEO_GRADY"] = "%.2f" % (py_+guy*L)
sch["GEO_VELX"] = "%.2f" % (px_+vux*L*1.05);   sch["GEO_VELY"] = "%.2f" % (py_+vuy*L*1.05)
sch["GEO_TAN"] = "M%.2f %.2f L%.2f %.2f" % (px_-tux*74, py_-tuy*74, px_+tux*74, py_+tuy*74)
sch["GEO_CX"] = str(cx); sch["GEO_CY"] = str(cy)

ag = math.atan2(guy, gux); av = math.atan2(vuy, vux)
sweep = (av - ag + math.pi) % (2*math.pi) - math.pi
arc = []
for i in range(41):
    a = ag + sweep*i/40
    arc.append("%s%.2f %.2f" % ("M" if i == 0 else "L", px_ + 34*math.cos(a), py_ + 34*math.sin(a)))
sch["GEO_ARC"] = "".join(arc)
am = ag + sweep/2
sch["GEO_ANGX"] = "%.2f" % (px_ + 52*math.cos(am))
sch["GEO_ANGY"] = "%.2f" % (py_ + 52*math.sin(am) + 4)
sch["GEO_ANG"] = "%.0f" % abs(math.degrees(sweep))
sch["GEO_VLX2"] = "%.2f" % (px_ + vux*L*1.05 + 15)
sch["GEO_VLY2"] = "%.2f" % (py_ + vuy*L*1.05 - 24)
# label anchors just past each arrow tip
sch["GEO_GLX"] = "%.2f" % (px_+gux*(L+16)); sch["GEO_GLY"] = "%.2f" % (py_+guy*(L+16)+12)
sch["GEO_VLX"] = "%.2f" % (px_+vux*(L+18)); sch["GEO_VLY"] = "%.2f" % (py_+vuy*(L+18)-12)
print("angle between grad V and f: %.1f deg" % abs(math.degrees(sweep)))
print("pt", px_, py_, "gradtip", px_+gux*L, py_+guy*L, "veltip", px_+vux*L*1.05, py_+vuy*L*1.05)
out.update(sch)
with open("frag.json", "w") as fh:
    json.dump(out, fh)
print("total fragments:", len(out))
