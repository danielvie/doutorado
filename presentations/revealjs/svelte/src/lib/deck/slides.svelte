<script lang="ts">

    import { onMount } from 'svelte'

    import Reveal from "reveal.js";
    import MarkDown from "reveal.js/plugin/markdown/markdown"
    import Highlight from "reveal.js/plugin/highlight/highlight"
    import Notes from "reveal.js/plugin/Notes/Notes"
    import RevealMath from "reveal.js/plugin/math/math";
    
    import "reveal.js/dist/reveal.css"
    import "reveal.js/dist/theme/black.css"
    import "reveal.js/plugin/highlight/monokai.css"
    
    import 'katex/dist/katex.min.css'

    onMount(() => {
        const deck = new Reveal({
        autoAnimateEasing: 'easy',
            autoAnimateDuration: 1,
            hash: true,
            controls: true,
            progress: true,
        })
        deck.initialize({
            hash: true,

            // katex: {
            //     local: "node_modules/katex"
            // },

            mathjax3: {
                mathjax: 'https://cdn.jsdelivr.net/npm/mathjax@3/es5/tex-mml-chtml.js',
                tex: {
                    inlineMath: [['$', '$'], ['\\(', '\\)']]
                },
                options: {
                    skipHtmlTags: ['script', 'noscript', 'style', 'textarea', 'pre']
                },
            },




            plugins: [MarkDown, Highlight, Notes, RevealMath.KaTeX]
        })
    })
</script>

<div class="reveal">
    <div class="slides">
        <section>
            <h2>The Lorenz Equations</h2>
            <!--             
            <Katex>
                ax^2
            </Katex> -->
            
            <p class="fragment fade-in-then-out">
                \[\begin{aligned}
                \dot{x} &amp; = \sigma(y-x) \\
                \end{aligned} \]
            </p>

        </section>

        <section>slide 2</section>
    </div>
</div>