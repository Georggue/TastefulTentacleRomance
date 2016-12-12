using Framework;
using OpenTK.Graphics.OpenGL;
using System.Text;
using System;
using System.Drawing;
using OpenTK;
using OpenTK.Input;

namespace Example
{
	public class PostProcessingExample
	{
		private FBO fbo;
		private Texture texA;
        private Texture texB;
        private Texture activeTex;
		private Shader shaderCopy;
		private Shader shaderSource;
        private bool _pingPong = false;
        private Vector2 mousePos;
        private MouseDevice _mouse;

		public PostProcessingExample(int width, int height,MouseDevice mouse)
		{
            _mouse = mouse;
            fbo = new FBO();
            texA = Texture.Create(width, height);
            texB = Texture.Create(width, height);
            activeTex = texA;
            shaderCopy = PixelShader.Create(PixelShader.Copy);
			shaderSource = PixelShader.Create(Encoding.UTF8.GetString(Resources.gameOfLife1));
		}

		public void Draw(bool doPostProcessing, int width, int height, float time)
		{
            var last = (activeTex == texA) ? texA : texB;


            fbo.BeginUse(activeTex); //start drawing into texture
            GL.Viewport(0, 0, activeTex.Width, activeTex.Height);


            //draw stuff

            shaderSource.Begin();
            last.BeginUse();
			GL.Uniform2(shaderSource.GetUniformLocation("iResolution"), (float)width, (float)height);
			GL.Uniform1(shaderSource.GetUniformLocation("iGlobalTime"), time);
            mousePos.X =  (float)_mouse.X / width;
            mousePos.Y = (float)_mouse.Y / height;
            GL.Uniform2(shaderSource.GetUniformLocation("iMouse"), mousePos.X, 1-mousePos.Y);
            
            GL.DrawArrays(PrimitiveType.Quads, 0, 4);
            last.EndUse();
            shaderSource.End();

            fbo.EndUse(); //stop drawing into texture

            GL.Viewport(0, 0, width, height);

            activeTex.BeginUse();
            shaderCopy.Begin();
            GL.DrawArrays(PrimitiveType.Quads, 0, 4);
            shaderCopy.End();
            activeTex.EndUse();

            activeTex = last;
        }

        internal void handleMouse(Point position)
        {
            mousePos.X = (float)position.X;
            mousePos.Y = (float)position.Y;
        }
    }
}
