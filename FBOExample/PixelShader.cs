using Framework;

namespace Example
{
	public class PixelShader
	{
		public const string Copy = @"
			#version 430 core
			uniform sampler2D image;
			in vec2 uv;
			void main() {
				vec3 image = texture(image, uv).rgb;
				gl_FragColor = vec4(image, 1.0);
			}";

		public static Shader Create(string fragmentShaderText)
		{
			string sVertexShader = @"
				#version 130				
				out vec2 uv; 
				void main() {
					const vec2 vertices[4] = vec2[4](vec2(-1.0, -1.0),
                                    vec2( 1.0, -1.0),
                                    vec2( 1.0,  1.0),
                                    vec2(-1.0,  1.0));
					vec2 pos = vertices[gl_VertexID];
					uv = pos * 0.5 + 0.5;
					gl_Position = vec4(pos, 1.0, 1.0);
				}";
			return ShaderLoader.FromStrings(sVertexShader, fragmentShaderText);
		}
	}
}
