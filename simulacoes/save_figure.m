function save_figure(f, name, addr, config)


    figWidth = 10;
    figHeight = 8; 

    if nargin == 4
        figWidth = config.fig_width;
        figHeight = config.fig_height;
    end

    fprintf("saving %s\n", name);

    % change fig properties
    f.PaperSize = [figWidth, figHeight];
    f.PaperPosition = [0 0 figWidth figHeight];
    
    % saving the file
    saveas(f, name, 'pdf');

    % copying to destination folder
    if ~strcmp(addr, "")
        copyfile(name, addr);
    end

end