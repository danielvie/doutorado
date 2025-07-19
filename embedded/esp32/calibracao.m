function calibracao()
  measures = [
    0.10, 0.00;
    0.20, 0.07;
    0.30, 0.17;
    0.40, 0.26;
    0.50, 0.36;
    0.60, 0.46;
    0.70, 0.56;
    0.80, 0.66;
    0.90, 0.76;
    1.00, 0.86;
    1.10, 0.96;
    1.20, 1.06;
    1.30, 1.16;
    1.40, 1.27;
    1.50, 1.37;
    1.60, 1.46;
    1.70, 1.56;
    1.80, 1.67;
    1.90, 1.76;
    2.00, 1.86;
    2.10, 1.96;
    2.20, 2.06;
    2.30, 2.16;
    2.40, 2.27;
    2.50, 2.37;
    2.60, 2.49;
    2.70, 2.61;
    2.80, 2.75;
    2.90, 2.90;
    3.00, 3.07;
    3.10, 3.26;
    3.20, 3.30;
    3.30, 3.30;];


  % y = measures(1:25,1); % value from multimeter
  % H = [y*0+1, measures(1:25,2)];

  % x_est = (H'*H)\H'*y;

  % values = measures(:, 2);

  % disp(foo(2.356));

  N = size(measures,1);
  estimates = zeros(N, 1);
  for i = 1:N
    estimate = foo(measures(i, 1));
    estimates(i) = estimate;
  end
  
  disp(estimates)

  hold off;
  plot(measures(:,1), measures(:,2), '-*');
  hold on;
  plot(measures(:,1), estimates, '--');
  grid on;


  % a = values;
  % plot(a(:,1),'-*');
  % hold on;
  % plot(a(:,2)+0.1323,'-*');
  % hold off;
  % grid on;

end

function y = foo(x)
  % 0.1, 0.2, 0.3, ...
  values = [0, 0.0700, 0.1700, 0.2600, 0.3600, 0.4600, 0.5600, 0.6600, 0.7600, 0.8600, 0.9600, 1.0600, 1.1600, 1.2700, 1.3700, 1.4600, 1.5600, 1.6700, 1.7600, 1.8600, 1.9600, 2.0600, 2.1600, 2.2700, 2.3700, 2.4900, 2.6100, 2.7500, 2.9000, 3.0700, 3.2600, 3.3000, 3.3000];
  
  if (x > 3.2)
    y = x;
    return
  end

  x_i = floor(x*10);
  x_f = rem(x*10,1);

  a = values(x_i);
  b = values(x_i+1);

  y = a + (b-a)*x_f;
end