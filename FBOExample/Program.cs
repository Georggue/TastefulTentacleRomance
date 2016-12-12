using Framework;
using OpenTK;
using OpenTK.Input;
using System;
using System.Diagnostics;

namespace Example
{
	class MyApplication
	{
		private GameWindow gameWindow = new GameWindow(1024, 1024);
		private Stopwatch globalTime = new Stopwatch();
		private PostProcessingExample postProcessingExample;

		[STAThread]
		public static void Main()
		{
			var app = new MyApplication();
			//run the update loop, which calls our registered callbacks
			app.gameWindow.Run();
		}

		private MyApplication()
		{
			//registers a callback for drawing a frame
			gameWindow.RenderFrame += GameWindow_RenderFrame;
			gameWindow.RenderFrame += (sender, e) => gameWindow.SwapBuffers();
			gameWindow.KeyDown += GameWindow_KeyDown;         
            
            try
			{
				postProcessingExample = new PostProcessingExample(gameWindow.Width, gameWindow.Height, gameWindow.Mouse);
			}
			catch (ShaderException e)
			{
				Console.WriteLine(e.Log);
			}

			globalTime.Start();
		}

     

        private void GameWindow_KeyDown(object sender, KeyboardKeyEventArgs e)
		{
			if (Key.Escape == e.Key)
			{
				gameWindow.Exit();
			}
		}

		private void GameWindow_RenderFrame(object sender, FrameEventArgs e)
		{
			bool doPostProcessing = !Keyboard.GetState()[Key.Space];
			float time = (float)globalTime.Elapsed.TotalSeconds;
			int width = gameWindow.Width;
			int height = gameWindow.Height;

			postProcessingExample.Draw(doPostProcessing, width, height, time);
		}
	}
}