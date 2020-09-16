local M = {}

function M.donut_3d(print, A, B)
  local sin, cos, floor, pi = math.sin, math.cos, math.floor, math.pi
  local theta_spacing = 0.07;
  local phi_spacing   = 0.02;

  local R1 = 1;
  local R2 = 2;
  local K2 = 5;
  local screen_width, screen_height = 120, 60
  -- Calculate K1 based on screen size: the maximum x-distance occurs
  -- roughly at the edge of the torus, which is at x=R1+R2, z=0.  we
  -- want that to be displaced 3/8ths of the width of the screen, which
  -- is 3/4th of the way from the center to the side of the screen.
  -- screen_width*3/8 = K1*(R1+R2)/(K2+0)
  -- screen_width*K2*3/(8*(R1+R2)) = K1
  local K1 = screen_width*K2*3/(8*(R1+R2));

  local cosA,sinA,cosB,sinB = cos(A), sin(A), cos(B), sin(B)
  local output = {}
  local zbuffer = {}
  for i=1,screen_width do
    output[i] = {}
    zbuffer[i] = {}
    for j=1,screen_height do
      output[i][j] = ' '
      zbuffer[i][j] = 0
    end
  end

  for theta=0, 2*pi, theta_spacing do
    -- precompute sines and cosines of theta
    local costheta, sintheta = cos(theta), sin(theta)

    -- phi goes around the center of revolution of a torus
    for phi=0, 2*pi, phi_spacing do
      -- precompute sines and cosines of phi
      local cosphi, sinphi = cos(phi), sin(phi)

      -- the x,y coordinate of the circle, before revolving (factored
      -- out of the above equations)
      local circlex = R2 + R1*costheta
      local circley = R1*sintheta

      -- final 3D (x,y,z) coordinate after rotations, directly from
      -- our math above
      local x = circlex*(cosB*cosphi + sinA*sinB*sinphi)
      - circley*cosA*sinB 
      local y = circlex*(sinB*cosphi - sinA*cosB*sinphi)
      + circley*cosA*cosB
      local z = K2 + cosA*circlex*sinphi + circley*sinA
      local ooz = 1/z  -- "one over z"

      -- x and y projection.  note that y is negated here, because y
      -- goes up in 3D space but down on 2D displays.
      local xp = floor(screen_width/2 + K1*ooz*x) + 1
      local yp = floor(screen_height/2 - K1*ooz*y) + 1

      -- calculate luminance.  ugly, but correct.
      local L = cosphi*costheta*sinB - cosA*costheta*sinphi -
      sinA*sintheta + cosB*(cosA*sintheta - costheta*sinA*sinphi)
      -- L ranges from -sqrt(2) to +sqrt(2).  If it's < 0, the surface
      -- is pointing away from us, so we won't bother trying to plot it.
      if L > 0 then
        -- test against the z-buffer.  larger 1/z means the pixel is
        -- closer to the viewer than what's already plotted.
        if xp > screen_width or yp > screen_height or xp < 1 or yp < 1 then
          break
        end

        if ooz > zbuffer[xp][yp] then
          zbuffer[xp][yp] = ooz
          local luminance_index = floor(L*8)
          -- luminance_index is now in the range 0..11 (8*sqrt(2) = 11.3)
          -- now we lookup the character corresponding to the
          -- luminance and plot it in our output:
          output[xp][yp] = string.sub(".,-~:;=!*#$@", luminance_index, luminance_index)
        end
      end
    end
  end

  -- now, dump output[] to the screen.
  -- bring cursor to "home" location, in just about any currently-used
  -- terminal emulation mode
  for j = 1, screen_height do
    local line = ""
    for i = 1, screen_width do
      line = line .. output[i][j]
    end
    print(line)
  end
end

for A=0, math.pi*2, 0.1 do
  for B=0, math.pi*2, 0.1 do
    print("\x1b[H")
    M.donut_3d(print, A, B)
  end
end
return M
