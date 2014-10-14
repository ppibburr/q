def main():int
    running = true;

    # Initialize GLFW
    GLFW.glfwInit();

    # Open an OpenGL window (you can also try Mode.FULLSCREEN)
    q=GLFW.glfwOpenWindow(640, 480, 0, 0, 0, 0, 0, 0, GLFW::Mode.WINDOW)
    if !q
        GLFW.glfwTerminate();
        return(1);
    end

    # Main loop
    while running
        # OpenGL rendering goes here...
        GL.glClear(GL::GL_COLOR_BUFFER_BIT);
        GL.glBegin(GL::GL_TRIANGLES);
            GL.glVertex3f( 0.0.f, 1.0.f, 0.0.f);
            GL.glVertex3f(-1.0.f,-1.0.f, 0.0.f);
            GL.glVertex3f( 1.0.f,-1.0.f, 0.0.f);
        GL.glEnd();

        # Swap front and back rendering buffers
        GLFW.glfwSwapBuffers();
        # Check if ESC key was pressed or window was closed
        running = !GLFW.glfwGetKey(GLFW.Key.ESC) && bool(GLFW.glfwGetWindowParam(GLFW.WindowParam.OPENED));
    end

    # Close window and terminate GLFW
    GLFW.glfwTerminate();

    # Exit program
    return(0);
end
