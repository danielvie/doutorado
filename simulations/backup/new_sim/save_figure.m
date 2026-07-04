function save_figure(f, name)

    figWidth = 10;  % or any desired width in inches
    figHeight = 8; % or any desired height in inches

    f.PaperSize = [figWidth, figHeight];
    f.PaperPosition = [0 0 figWidth figHeight];
    
    saveas(f, name, 'pdf');

end