function save_figure(f, name, addr)

    fprintf("saving %s\n", name);

    % change fig properties
    figWidth = 10;
    figHeight = 8; 

    
    f.PaperSize = [figWidth, figHeight];
    f.PaperPosition = [0 0 figWidth figHeight];
    
    % saving the file
    saveas(f, name, 'pdf');

    % copying to destination folder
    if nargin == 3
        copyfile(name, addr);
    end

end