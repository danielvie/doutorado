P0 = [1, 0, 1];
P1 = [0, 1, 1];
P2 = [0, 0, 1];
P3 = [1, 2, 1];

L1 = cross(P0, P1);
L2 = cross(P2, P3);

X  = cross(L1, L2);

target = [X(1) X(2)]/X(3)