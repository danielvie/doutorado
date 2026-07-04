function save_figure(f, name, addr)

    figWidth = 10;
    figHeight = 8; 

    fprintf("saving %s in %s\n", name, addr);

    % Ensure directory exists
    if ~exist(addr, 'dir')
        mkdir(addr);
    end

    % change fig properties
    f.Units = 'inches';
    f.Position = [1 1 figWidth figHeight];
    f.PaperSize = [figWidth, figHeight];
    f.PaperPosition = [0 0 figWidth figHeight];
    
    % full path for saving
    full_path = fullfile(addr, name);

    % saving the file as PDF and PNG for convenience
    saveas(f, full_path, 'pdf');
    saveas(f, full_path, 'png');

end
