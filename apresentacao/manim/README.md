


#### installation macOS
https://docs.manim.community/en/stable/installation/macos.html


To install all required dependencies for installing Manim (namely: ffmpeg, Python, and some required Python packages), run:

```bash
brew install py3cairo ffmpeg
```

on Apple silicon-based machines, some additional dependencies are required: 

```bash
brew install pango pkg-config scipy
```

After all required dependencies are installed, run:

```bash
pip3 install manim
```