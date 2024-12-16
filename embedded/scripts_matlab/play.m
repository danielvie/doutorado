
time = [1, 2, 4];
mode = [8, 9, 0];

% convert arrays to strings
time_str = sprintf('%d,', time);
mode_str = sprintf('%d,', mode);

% concatenate strings
result = strcat(time_str, ";", mode_str, ";");

% remove trailing commas
result = strrep(result, ",;", ";");

disp(result)