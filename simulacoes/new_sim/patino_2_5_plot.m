

% renomeando variaveis
vc1 = y(:,1);
vc2 = y(:,2);
i_l = y(:,3);

% plot dos resultados
close all;

f1 = figure(1);
plot(t, vc1);

grid on;
xlabel('t - time(s)');
ylabel('V_{c1} [V]');
set(gca,'fontsize', 15);


f2 = figure(2);
plot(t, vc2);

grid on;
xlabel('t - time(s)');
ylabel('V_{c2} [V]');
set(gca,'fontsize', 15);

f3 = figure(3);
plot(t, i_l);

grid on;
xlabel('t - time(s)');
ylabel('i_L [A]');
set(gca,'fontsize', 15);

f4 = figure(4);
plot3(vc1, vc2, i_l, 'k');

grid on;
xlabel('V_{c1} [V]');
ylabel('V_{c2} [V]');
zlabel('i_L [A]');
set(gca,'fontsize', 15);




mref = config.modes + 1;
mref = [mref, mref(1)];
tref = config.Ts;

% t = bla.t;
m1 = m + 1;
% y = bla.y;

tend = t(end);

while (tref(end) < t(end))
    tref = [tref, tref + tref(end)];
    mref = [mref, mref];
end

f5 = figure();
stairs(tref, mref, 'linew', 2);
hold on;
stairs(t, m1, 'linew', 2, 'linestyle', '--');
hold off;
xlim([0, 1.46e-3]);
grid on;
xlabel('time (s)');
ylabel('mode');
set(gca,'fontsize', 15);
legend('modes target trajectory', 'modes simulation');


%% saving figures
save_figure(f1, "graf_ex2_1.pdf")
save_figure(f2, "graf_ex2_2.pdf")
save_figure(f3, "graf_ex2_3.pdf")
save_figure(f4, "graf_ex2_4.pdf")
save_figure(f5, "graf_ex2_5.pdf");

%% copy figures

% cap 2
copyfile("graf_ex2_1.pdf", "../../LATEX_tese/Cap4/fig/");
copyfile("graf_ex2_2.pdf", "../../LATEX_tese/Cap4/fig/");
copyfile("graf_ex2_3.pdf", "../../LATEX_tese/Cap4/fig/");
copyfile("graf_ex2_4.pdf", "../../LATEX_tese/Cap4/fig/");

% cap 4
copyfile("graf_ex2_5.pdf", "../../LATEX_tese/Cap4/fig/");