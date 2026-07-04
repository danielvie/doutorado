from manim import *


# \int_{t_{#3_#1}}^{t_{#4_#2}}
# {e^{A_#2(t_{#2} - \tau)} B_#2 d \tau}
def int_lin_aa(a, b, c, d) -> str:
    """funcao para gerar integral do latex"""

    base = r"\int_{t_{#3_#1}}^{t_{#4_#2}} {e^{A_#2(t_{#2} - \tau)} B_#2 d \tau}"
    base = base.replace("#1", a)
    base = base.replace("#2", b)
    base = base.replace("#3", c)
    base = base.replace("#4", d)
    return base


class OpeningManim(Scene):
    def construct(self):
        title = Tex(r"This is some \LaTeX")
        basel = MathTex(
            r"x(t_1) = e^{A_1(t_1-t_0)}x(t_0) + " + int_lin_aa("0", "1", "", "")
        )
        basel2 = MathTex(
            r"x(t_1) = e^{A_1(t_1-t_0)}x(t_0) + " + int_lin_aa("90", "1", "", "")
        )
        VGroup(title, basel, basel2).arrange(DOWN)
        # VGroup(title, basel2).arrange(DOWN)
        self.play(
            Write(title),
            FadeIn(basel, shift=DOWN),
            FadeIn(basel2, shift=DOWN),
        )
        self.wait()

        transform_title = Tex("That was a transform")
        transform_title.to_corner(UP + LEFT)
        self.play(
            Transform(title, transform_title),
            LaggedStart(*[FadeOut(obj, shift=DOWN) for obj in basel]),
            basel2.animate.set_color(BLUE),
        )

        self.wait()

        ## inicio

        # Create the initial equation
        integral_part = MathTex(r"\int_a^b{x^2 + 2}\, dx")
        integral_part.set_color(WHITE)

        left_eq = MathTex(r"A =")
        right_eq = MathTex(r" +\; C")

        equation = VGroup(left_eq, integral_part, right_eq).arrange(RIGHT)

        # Display the equation
        self.play(FadeIn(equation))
        self.wait(1)

        # Change the color of the integral part to blue
        # integral_part = equation[0][2:11]  # Extract the integral part
        integral_part.generate_target()
        integral_part.target.set_color(RED)
        self.play(MoveToTarget(integral_part))
        self.wait(1)

        # Change the value of the integral to pi
        new_integral = MathTex(r"\pi", font_size=79)
        new_integral.move_to(integral_part)
        new_integral.set_color(BLUE_B)
        self.play(ReplacementTransform(integral_part, new_integral))

        # equation[0].next_to(integral_part, LEFT, aligned_edge=LEFT)
        # equation[2].next_to(integral_part, RIGHT, aligned_edge=RIGHT)

        # space = 0.2
        # integral_part.next_to(left_eq, RIGHT, buff=space)
        # right_eq.next_to(integral_part, RIGHT, buff=space)
        # equation.add(space * LEFT)

        self.wait(2)
