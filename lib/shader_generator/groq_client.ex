defmodule ShaderGenerator.GroqClient do
  @moduledoc """
  Client for interacting with Groq AI API to generate shader code
  """

  require Logger
  alias Req

  @groq_api_url "https://api.groq.com/openai/v1/chat/completions"

  @doc """
  Generates a shader based on the provided prompt by calling the Groq API.
  Returns {:ok, shader_code} on success or {:error, reason} on failure.
  """
  def generate_shader(prompt) do
    api_key = System.get_env("GROQ_API_KEY")

    if is_nil(api_key) or api_key == "" do
      Logger.error("Groq API key not configured")
      {:error, "API key not configured"}
    else
      do_generate_shader(prompt, api_key)
    end
  end

  defp do_generate_shader(prompt, api_key) do
    headers = [
      {"Content-Type", "application/json"},
      {"Authorization", "Bearer #{api_key}"}
    ]

    body = %{
      model: "llama-3.3-70b-versatile",
      messages: [
        %{
          role: "system",
          content:
            "You are a **GLSL shader programming expert** specialized in **WebGL 1.0** (GLSL ES 1.00). Your task is to generate **fully functional, error-free shaders** with high accuracy.

### **WebGL 1.0 Rules (Must Follow)**
1. **GLSL ES 1.00 Compliance**
   - Use `precision mediump float;` for compatibility.
   - Use `gl_FragColor` instead of `out vec4 fragColor`.
   - **No array initializers** (manually assign values instead).
   - **No matrix operations inside loops** (define transformations explicitly).

2. **2D & 3D Shader Generation**
   - Generate **both 2D procedural effects (patterns, gradients, noise) and 3D shaders**.
   - Use **signed distance functions (SDFs)** and **ray marching** for 3D rendering.
   - Implement **normal calculations** for shading.
   - Apply **camera transformations** (rotation matrices, perspective adjustments).
   - Ensure **correct lighting calculations** for realistic shading.

3. **Error-Free, Optimized Code**
   - **No syntax errors** (ensure all variables are properly declared).
   - **No missing semicolons or invalid GLSL syntax**.
   - **No undefined functions** (always declare and define before usage).
   - Avoid complex **one-liner logic** that may cause parsing issues.

4. **Strict Response Format**
   - **Do not include explanations.**
   - **Only output valid GLSL code** inside triple backticks (` ```glsl `).
   - Do not insert any incorrect or experimental syntax.

---
### **Example Shader Outputs (Must Match This Quality)**
1. **Ray-marched 3D Cube**
   ```glsl
   #ifdef GL_ES
   precision mediump float;
   #endif

   uniform float u_time;
   uniform vec2 u_resolution;

   #define MAX_STEPS 100
   #define MAX_DIST 5.0
   #define SURF_DIST 0.001

   // Rotation matrices
   mat3 rotateY(float a) {
       float c = cos(a), s = sin(a);
       return mat3(c, 0, s, 0, 1, 0, -s, 0, c);
   }

   mat3 rotateX(float a) {
       float c = cos(a), s = sin(a);
       return mat3(1, 0, 0, 0, c, -s, 0, s, c);
   }

   // Signed Distance Function (SDF) for a cube
   float sdfCube(vec3 p, vec3 size) {
       vec3 d = abs(p) - size;
       return min(max(d.x, max(d.y, d.z)), 0.0) + length(max(d, 0.0));
   }

   // Ray marching function
   float rayMarch(vec3 ro, vec3 rd) {
       float dO = 0.0;
       for (int i = 0; i < MAX_STEPS; i++) {
           vec3 p = ro + rd * dO;
           float dS = sdfCube(p, vec3(0.3)); // Cube size
           dO += dS;
           if (dS < SURF_DIST || dO > MAX_DIST) break;
       }
       return dO;
   }

   // Compute normal from SDF
   vec3 getNormal(vec3 p) {
       vec2 e = vec2(0.001, 0.0);
       return normalize(vec3(
           sdfCube(p + e.xyy, vec3(0.3)) - sdfCube(p - e.xyy, vec3(0.3)),
           sdfCube(p + e.yxy, vec3(0.3)) - sdfCube(p - e.yxy, vec3(0.3)),
           sdfCube(p + e.yyx, vec3(0.3)) - sdfCube(p - e.yyx, vec3(0.3))
       ));
   }

   // Simple lighting
   float getLight(vec3 p, vec3 lightPos) {
       vec3 n = getNormal(p);
       vec3 l = normalize(lightPos - p);
       return max(dot(n, l), 0.0);
   }

   void main() {
       vec2 uv = (gl_FragCoord.xy - 0.5 * u_resolution.xy) / u_resolution.y;

       vec3 ro = vec3(0.0, 0.0, -2.5); // Camera position (moved back)
       vec3 rd = normalize(vec3(uv, 1.0)); // Ray direction

       // Apply rotation
       mat3 rot = rotateY(u_time * 0.5) * rotateX(u_time * 0.3);
       ro = rot * ro;
       rd = rot * rd;

       // Ray march scene
       float dist = rayMarch(ro, rd);
       vec3 color = vec3(0.1, 0.1, 0.2); // Background color

       if (dist < MAX_DIST) {
           vec3 p = ro + rd * dist;
           float light = getLight(p, vec3(2.0, 2.0, -1.0)); // Light position
           color = vec3(light * 1.2, light * 0.5, light * 0.2);
       }

       gl_FragColor = vec4(color, 1.0);
   }

"
        },
        %{
          role: "user",
          content: build_llm_prompt(prompt)
        }
      ],
      temperature: 0.7
    }

    Logger.debug("Sending request to Groq API")

    case Req.post(@groq_api_url, json: body, headers: headers, receive_timeout: 30_000) do
      {:ok, %Req.Response{status: 200, body: response_body}} ->
        Logger.debug("Received successful response from Groq API")
        shader_code = get_in(response_body, ["choices", Access.at(0), "message", "content"])

        cleaned_code =
          if shader_code, do: String.replace(shader_code, ~r/```glsl|```/, ""), else: ""

        {:ok, String.trim(cleaned_code)}

      {:ok, %Req.Response{status: status_code, body: error_body}} ->
        detailed_error = "Groq API error: #{status_code} - #{inspect(error_body)}"
        Logger.error(detailed_error)
        {:error, detailed_error}

      {:error, reason} ->
        detailed_error = "HTTP request failed: #{inspect(reason)}"
        Logger.error(detailed_error)
        {:error, detailed_error}
    end
  end

  defp build_llm_prompt(user_prompt) do
    """
    Generate a valid GLSL shader code based on the following description: "#{user_prompt}".

    The shader should:
    1. Be a complete, compilable GLSL fragment shader
    2. Include comments explaining key parts
    3. Use uniform variables for any animation effects (time, resolution)
    4. Follow this basic structure:

    ```glsl
    #ifdef GL_ES
    precision mediump float;
    #endif

    uniform float u_time;
    uniform vec2 u_resolution;

    void main() {
      // Shader code here
      // ...

      // Final color output
      gl_FragColor = vec4(color, 1.0);
    }
    ```

    Return ONLY the shader code without any additional text, explanations, or markdown.
    """
  end
end
