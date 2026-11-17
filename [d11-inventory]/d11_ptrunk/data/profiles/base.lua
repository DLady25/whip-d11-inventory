-- d11_ptrunk: perfis do porta-malas fisico, carros do GTA V. Um bloco por carro, pelo nome do modelo.
--   spawn  = a area util (centro x/y/z e o poligono areaPoints, no espaco do carro). SEM ela o carro abre o
--            porta-malas normal do WHIP. E o unico obrigatorio.
--   camera = camera, lado de acesso (rear/front) e ponto de pe; sem ela vale a da classe (class, no fim).
--   light  = luzes do porta-malas aberto (spots); sem ela, sem luz propria.
-- Calibrados no velocity-physicaltrunk da D12 (retrato de 2026-09-25) e no WHIP. Calibre/recalibre em jogo com o
-- wizard (/ptrunkwizard start) e exporte com /ptrunkexport para mandar de volta ao repositorio.
-- Os carros base que o NoPixel 4 substitui estao em nopixel.lua (calibrados no modelo do NP).
return {
 vehicles = {
  adder = {
   spawn = { x = 0.000, y = 1.759, z = -0.064, areaPoints = { { x = 0.363, y = 1.938 }, { x = 0.472, y = 1.692 }, { x = 0.548, y = 1.329 }, { x = 0.114, y = 1.363 }, { x = -0.540, y = 1.375 }, { x = -0.364, y = 1.947 }, { x = 0.038, y = 1.985 }, { x = 0.201, y = 1.967 } } },
   camera = { access = 'front', triggerRadius = 2.35, standOffset = 1.40, camLocalX = -0.003, camLocalY = 2.494, camLocalZ = 0.532, lookLocalX = -0.021, lookLocalY = 0.336, lookLocalZ = -0.730, fov = 52.0 },
   light = { spots = { { pos = { x = -0.016, y = 1.867, z = 0.552 }, look = { x = 0.024, y = 1.549, z = -0.114 }, color = { r = 255, g = 255, b = 190 }, brightness = 16.72, spotFov = 33.40, distance = 2.20, radius = 12.00, falloff = 18.00 } } },
  },
  aleutian = {
   spawn = { x = 0.000, y = -1.885, z = 0.040, areaPoints = { { x = -0.609, y = -1.213 }, { x = -0.102, y = -1.221 }, { x = 0.603, y = -1.236 }, { x = 0.599, y = -1.459 }, { x = 0.604, y = -1.974 }, { x = 0.840, y = -2.123 }, { x = 0.825, y = -2.472 }, { x = 0.628, y = -2.518 }, { x = 0.431, y = -2.533 }, { x = 0.045, y = -2.559 }, { x = -0.384, y = -2.537 }, { x = -0.825, y = -2.484 }, { x = -0.851, y = -2.115 }, { x = -0.615, y = -1.990 }, { x = -0.598, y = -1.904 } } },
   camera = { access = 'rear', triggerRadius = 2.90, standOffset = 1.95, camLocalX = -0.028, camLocalY = -3.012, camLocalZ = 0.836, lookLocalX = 0.122, lookLocalY = -0.765, lookLocalZ = -0.251, fov = 52.0 },
   light = { spots = { { pos = { x = -0.016, y = -2.729, z = 1.384 }, look = { x = 0.000, y = -2.183, z = -0.010 }, color = { r = 255, g = 235, b = 190 }, brightness = 12.80, spotFov = 40.70, distance = 2.20, radius = 12.00, falloff = 18.00 } } },
  },
  ambulance = {
   spawn = { x = 0.016, y = -3.191, z = -0.144, areaPoints = { { x = -0.722, y = -2.450 }, { x = -0.344, y = -2.453 }, { x = -0.006, y = -2.457 }, { x = 0.374, y = -2.457 }, { x = 0.726, y = -2.459 }, { x = 0.718, y = -2.840 }, { x = 0.716, y = -3.341 }, { x = 0.708, y = -3.791 }, { x = 0.421, y = -3.787 }, { x = -0.015, y = -3.786 }, { x = -0.404, y = -3.779 }, { x = -0.721, y = -3.785 }, { x = -0.715, y = -3.437 }, { x = -0.717, y = -3.146 } } },
   camera = { access = 'rear', triggerRadius = 3.00, standOffset = 2.00, camLocalX = 0.114, camLocalY = -4.663, camLocalZ = 1.069, lookLocalX = 0.089, lookLocalY = -2.586, lookLocalZ = -0.322, fov = 52.0 },
   light = { spots = { { pos = { x = 0.016, y = -2.627, z = 1.616 }, look = { x = 0.000, y = -2.969, z = -0.194 }, color = { r = 255, g = 255, b = 190 }, brightness = 3.20, spotFov = 27.60, distance = 2.20, radius = 12.00, falloff = 18.00 } } },
  },
  asbo = {
   spawn = { x = -0.016, y = -1.483, z = 0.184, areaPoints = { { x = -0.518, y = -1.237 }, { x = -0.082, y = -1.229 }, { x = 0.524, y = -1.249 }, { x = 0.523, y = -1.657 }, { x = 0.156, y = -1.703 }, { x = -0.316, y = -1.707 }, { x = -0.524, y = -1.665 } } },
   camera = { access = 'rear', triggerRadius = 2.60, standOffset = 1.65, camLocalX = 0.108, camLocalY = -2.331, camLocalZ = 1.108, lookLocalX = 0.114, lookLocalY = -0.403, lookLocalZ = -0.484, fov = 52.0 },
   light = { spots = { { pos = { x = 0.040, y = -1.975, z = 1.232 }, look = { x = 0.000, y = -1.741, z = 0.702 }, color = { r = 255, g = 235, b = 190 }, brightness = 2.04, spotFov = 29.80, distance = 2.20, radius = 12.00, falloff = 18.00 } } },
  },
  asea = {
   spawn = { x = 0.000, y = -1.749, z = 0.080, areaPoints = { { x = -0.349, y = -1.191 }, { x = 0.361, y = -1.248 }, { x = 0.420, y = -1.771 }, { x = 0.430, y = -2.293 }, { x = -0.005, y = -2.320 }, { x = -0.367, y = -2.280 }, { x = -0.407, y = -1.838 } } },
   camera = { access = 'rear', triggerRadius = 2.60, standOffset = 1.55, camLocalX = 0.060, camLocalY = -3.071, camLocalZ = 0.707, lookLocalX = -0.011, lookLocalY = -0.748, lookLocalZ = -0.213, fov = 52.0 },
   light = { spots = { { pos = { x = -0.024, y = -2.473, z = 0.440 }, look = { x = 0.024, y = -1.815, z = -0.058 }, color = { r = 255, g = 255, b = 190 }, brightness = 1.50, spotFov = 52.70, distance = 1.10, radius = 12.00, falloff = 15.20 } } },
  },
  asterope = {
   spawn = { x = 0.000, y = -1.700, z = 0.064, areaPoints = { { x = -0.428, y = -1.250 }, { x = 0.434, y = -1.230 }, { x = 0.428, y = -1.354 }, { x = 0.556, y = -1.442 }, { x = 0.564, y = -1.906 }, { x = 0.652, y = -1.930 }, { x = 0.580, y = -2.130 }, { x = 0.400, y = -2.214 }, { x = -0.386, y = -2.224 }, { x = -0.587, y = -2.125 }, { x = -0.647, y = -1.947 }, { x = -0.556, y = -1.882 }, { x = -0.556, y = -1.438 }, { x = -0.444, y = -1.360 } } },
   camera = { access = 'rear', triggerRadius = 2.60, standOffset = 1.55, camLocalX = -0.000, camLocalY = -3.207, camLocalZ = 0.865, lookLocalX = -0.024, lookLocalY = -0.890, lookLocalZ = -0.072, fov = 52.0 },
   light = { spots = { { pos = { x = 0.000, y = -2.008, z = 0.464 }, look = { x = 0.000, y = -1.774, z = 0.014 }, color = { r = 255, g = 235, b = 190 }, brightness = 4.20, spotFov = 52.20, distance = 0.90, radius = 12.00, falloff = 18.00 } } },
  },
  asterope2 = {
   spawn = { x = 0.000, y = -2.024, z = 0.152, areaPoints = { { x = -0.593, y = -1.830 }, { x = -0.484, y = -1.779 }, { x = 0.474, y = -1.773 }, { x = 0.598, y = -1.838 }, { x = 0.619, y = -2.229 }, { x = 0.420, y = -2.254 }, { x = -0.028, y = -2.262 }, { x = -0.436, y = -2.262 }, { x = -0.622, y = -2.229 } } },
   camera = { access = 'rear', triggerRadius = 2.60, standOffset = 1.55, camLocalX = 0.028, camLocalY = -2.954, camLocalZ = 1.009, lookLocalX = 0.038, lookLocalY = -0.805, lookLocalZ = -0.268, fov = 52.0 },
   light = { spots = { { pos = { x = 0.000, y = -1.788, z = 0.504 }, look = { x = 0.000, y = -1.906, z = 0.174 }, color = { r = 255, g = 235, b = 190 }, brightness = 0.72, spotFov = 60.00, distance = 2.20, radius = 12.00, falloff = 18.00 } } },
  },
  baller = {
   spawn = { x = 0.000, y = -1.956, z = -0.048, areaPoints = { { x = -0.646, y = -1.186 }, { x = 0.666, y = -1.206 }, { x = 0.638, y = -2.230 }, { x = 0.685, y = -2.396 }, { x = 0.345, y = -2.521 }, { x = 0.004, y = -2.590 }, { x = -0.388, y = -2.551 }, { x = -0.690, y = -2.395 }, { x = -0.636, y = -2.282 } } },
   camera = { access = 'rear', triggerRadius = 3.10, standOffset = 2.05, camLocalX = -0.025, camLocalY = -3.846, camLocalZ = 0.623, lookLocalX = 0.003, lookLocalY = -1.396, lookLocalZ = 0.128, fov = 52.0 },
   light = { spots = { { pos = { x = 0.000, y = -1.960, z = 0.760 }, look = { x = 0.000, y = -1.974, z = -0.346 }, color = { r = 255, g = 235, b = 190 }, brightness = 2.88, spotFov = 46.30, distance = 2.20, radius = 12.00, falloff = 18.00 } } },
  },
  baller2 = {
   spawn = { x = 0.000, y = -2.146, z = -0.112, areaPoints = { { x = -0.508, y = -1.536 }, { x = 0.514, y = -1.516 }, { x = 0.510, y = -1.964 }, { x = 0.812, y = -1.952 }, { x = 0.700, y = -2.472 }, { x = 0.412, y = -2.568 }, { x = 0.012, y = -2.632 }, { x = -0.420, y = -2.576 }, { x = -0.728, y = -2.444 }, { x = -0.766, y = -2.226 }, { x = -0.809, y = -1.941 }, { x = -0.500, y = -1.968 } } },
   camera = { access = 'rear', triggerRadius = 3.10, standOffset = 2.05, camLocalX = 0.060, camLocalY = -3.565, camLocalZ = 0.669, lookLocalX = 0.036, lookLocalY = -1.225, lookLocalZ = -0.209, fov = 52.0 },
   light = { spots = { { pos = { x = 0.016, y = -1.774, z = 0.800 }, look = { x = -0.008, y = -2.052, z = -0.162 }, color = { r = 255, g = 235, b = 190 }, brightness = 6.00, spotFov = 43.80, distance = 2.20, radius = 12.00, falloff = 18.00 } } },
  },
  baller3 = {
   spawn = { x = 0.008, y = -2.130, z = -0.136, areaPoints = { { x = -0.823, y = -1.938 }, { x = -0.508, y = -1.971 }, { x = -0.507, y = -1.518 }, { x = -0.142, y = -1.526 }, { x = 0.512, y = -1.526 }, { x = 0.511, y = -1.968 }, { x = 0.816, y = -1.938 }, { x = 0.721, y = -2.461 }, { x = 0.378, y = -2.580 }, { x = 0.104, y = -2.613 }, { x = -0.297, y = -2.591 }, { x = -0.540, y = -2.531 }, { x = -0.717, y = -2.468 } } },
   camera = { access = 'rear', triggerRadius = 2.90, standOffset = 1.95, camLocalX = 0.008, camLocalY = -2.910, camLocalZ = 0.673, lookLocalX = 0.027, lookLocalY = -0.976, lookLocalZ = -0.911, fov = 52.0 },
   light = { spots = { { pos = { x = 0.008, y = -2.030, z = 0.952 }, look = { x = 0.008, y = -2.044, z = -3.439 }, color = { r = 255, g = 205, b = 190 }, brightness = 6.00, spotFov = 38.40, distance = 2.20, radius = 12.00, falloff = 18.00 } } },
  },
  baller4 = {
   spawn = { x = 0.000, y = -2.440, z = -0.112, areaPoints = { { x = -0.500, y = -2.278 }, { x = -0.504, y = -1.839 }, { x = -0.015, y = -1.839 }, { x = 0.503, y = -1.829 }, { x = 0.499, y = -2.279 }, { x = 0.789, y = -2.275 }, { x = 0.703, y = -2.795 }, { x = 0.423, y = -2.885 }, { x = -0.012, y = -2.936 }, { x = -0.416, y = -2.889 }, { x = -0.713, y = -2.795 }, { x = -0.806, y = -2.255 } } },
   camera = { access = 'rear', triggerRadius = 2.90, standOffset = 1.95, camLocalX = 0.009, camLocalY = -3.319, camLocalZ = 0.761, lookLocalX = 0.070, lookLocalY = -1.449, lookLocalZ = -0.897, fov = 52.0 },
   light = { spots = { { pos = { x = -0.016, y = -3.244, z = 1.144 }, look = { x = 0.000, y = -2.162, z = -0.171 }, color = { r = 255, g = 255, b = 190 }, brightness = 18.60, spotFov = 29.20, distance = 2.20, radius = 12.00, falloff = 18.00 } } },
  },
  baller5 = {
   spawn = { x = 0.000, y = -2.192, z = -0.132, areaPoints = { { x = -0.515, y = -1.974 }, { x = -0.504, y = -1.515 }, { x = -0.015, y = -1.514 }, { x = 0.503, y = -1.515 }, { x = 0.499, y = -1.976 }, { x = 0.789, y = -1.953 }, { x = 0.703, y = -2.435 }, { x = 0.423, y = -2.540 }, { x = -0.012, y = -2.583 }, { x = -0.416, y = -2.529 }, { x = -0.713, y = -2.423 }, { x = -0.806, y = -1.932 } } },
   camera = { access = 'rear', triggerRadius = 2.90, standOffset = 1.95, camLocalX = -0.012, camLocalY = -3.148, camLocalZ = 0.794, lookLocalX = 0.021, lookLocalY = -1.084, lookLocalZ = -0.617, fov = 52.0 },
   light = { spots = { { pos = { x = -0.016, y = -2.964, z = 1.144 }, look = { x = 0.000, y = -2.162, z = -0.171 }, color = { r = 255, g = 255, b = 190 }, brightness = 18.60, spotFov = 29.20, distance = 2.20, radius = 12.00, falloff = 18.00 } } },
  },
  baller6 = {
   camera = { access = 'rear', triggerRadius = 2.90, standOffset = 1.95, camLocalX = 0.007, camLocalY = -3.561, camLocalZ = 0.708, lookLocalX = -0.031, lookLocalY = -1.363, lookLocalZ = -0.481, fov = 52.0 },
  },
  banshee = {
   spawn = { x = 0.000, y = -1.686, z = 0.104, areaPoints = { { x = -0.604, y = -1.132 }, { x = 0.655, y = -1.104 }, { x = 0.563, y = -1.428 }, { x = 0.526, y = -2.028 }, { x = -0.528, y = -2.055 } } },
   camera = { access = 'rear', triggerRadius = 2.40, standOffset = 1.42, camLocalX = 0.010, camLocalY = -2.739, camLocalZ = 1.321, lookLocalX = -0.043, lookLocalY = -1.030, lookLocalZ = -0.503, fov = 52.0 },
   light = { spots = { { pos = { x = -0.025, y = -1.717, z = 1.472 }, look = { x = 0.000, y = -1.584, z = 0.054 }, color = { r = 255, g = 255, b = 190 }, brightness = 6.00, spotFov = 25.80, distance = 2.20, radius = 12.00, falloff = 18.00 } } },
  },
  benson = {
   spawn = { x = 0.000, y = -2.838, z = 0.072, areaPoints = { { x = -1.087, y = 0.427 }, { x = 1.083, y = 0.434 }, { x = 1.100, y = -4.776 }, { x = -1.096, y = -4.792 } } },
   camera = { access = 'rear', triggerRadius = 3.40, standOffset = 2.40, camLocalX = 0.010, camLocalY = -6.238, camLocalZ = 2.003, lookLocalX = 0.002, lookLocalY = -4.092, lookLocalZ = 0.720, fov = 52.0 },
  },
  bison = {
   spawn = { x = 0.000, y = -2.015, z = 0.160, areaPoints = { { x = -0.652, y = -1.565 }, { x = -0.841, y = -1.299 }, { x = -0.816, y = -0.950 }, { x = 0.834, y = -0.969 }, { x = 0.862, y = -1.249 }, { x = 0.644, y = -1.565 }, { x = 0.644, y = -2.445 }, { x = 0.852, y = -2.469 }, { x = 0.852, y = -2.841 }, { x = -0.844, y = -2.861 }, { x = -0.840, y = -2.513 }, { x = -0.646, y = -2.443 } } },
   camera = { access = 'rear', triggerRadius = 3.20, standOffset = 2.20, camLocalX = -0.001, camLocalY = -4.231, camLocalZ = 1.104, lookLocalX = 0.010, lookLocalY = -1.881, lookLocalZ = 0.250, fov = 52.0 },
   light = { spots = { { pos = { x = 0.000, y = -2.619, z = 0.928 }, look = { x = 0.000, y = -2.105, z = 0.150 }, color = { r = 255, g = 235, b = 190 }, brightness = 6.70, spotFov = 52.50, distance = 1.60, radius = 12.00, falloff = 18.00 } } },
  },
  bjxl = {
   spawn = { x = 0.000, y = -1.527, z = -0.328, areaPoints = { { x = -0.500, y = -1.213 }, { x = 0.514, y = -1.233 }, { x = 0.502, y = -1.313 }, { x = 0.596, y = -1.301 }, { x = 0.604, y = -1.949 }, { x = 0.300, y = -1.933 }, { x = -0.612, y = -1.949 }, { x = -0.604, y = -1.309 }, { x = -0.512, y = -1.285 } } },
   camera = { access = 'rear', triggerRadius = 2.90, standOffset = 1.95, camLocalX = 0.028, camLocalY = -3.057, camLocalZ = 0.886, lookLocalX = 0.006, lookLocalY = -0.915, lookLocalZ = -0.403, fov = 52.0 },
  },
  blade = {
   spawn = { x = 0.000, y = -1.858, z = 0.044, areaPoints = { { x = -0.364, y = -1.288 }, { x = 0.366, y = -1.290 }, { x = 0.366, y = -1.824 }, { x = 0.809, y = -1.819 }, { x = 0.763, y = -2.281 }, { x = -0.021, y = -2.320 }, { x = -0.765, y = -2.284 }, { x = -0.808, y = -1.816 }, { x = -0.364, y = -1.816 } } },
   camera = { access = 'rear', triggerRadius = 2.50, standOffset = 1.50, camLocalX = 0.038, camLocalY = -2.789, camLocalZ = 1.475, lookLocalX = -0.001, lookLocalY = -1.216, lookLocalZ = -0.468, fov = 52.0 },
   light = { spots = { { pos = { x = 0.000, y = -1.280, z = 0.371 }, look = { x = 0.000, y = -1.548, z = 0.098 }, color = { r = 255, g = 235, b = 190 }, brightness = 6.00, spotFov = 60.00, distance = 2.20, radius = 12.00, falloff = 18.00 } } },
  },
  blista = {
   spawn = { x = 0.000, y = -1.451, z = -0.477, areaPoints = { { x = -0.522, y = -1.172 }, { x = 0.516, y = -1.167 }, { x = 0.538, y = -1.637 }, { x = 0.021, y = -1.717 }, { x = -0.522, y = -1.652 } } },
   camera = { access = 'rear', triggerRadius = 2.60, standOffset = 1.64, camLocalX = -0.041, camLocalY = -2.320, camLocalZ = 0.739, lookLocalX = -0.021, lookLocalY = -0.490, lookLocalZ = -0.964, fov = 52.0 },
   light = { spots = { { pos = { x = 0.000, y = -1.687, z = 0.107 }, look = { x = -0.008, y = -1.380, z = -0.495 }, color = { r = 255, g = 235, b = 190 }, brightness = 2.02, spotFov = 46.90, distance = 2.20, radius = 12.00, falloff = 18.00 } } },
  },
  blista2 = {
   spawn = { x = 0.016, y = -1.583, z = 0.072, areaPoints = { { x = -0.388, y = -1.359 }, { x = 0.390, y = -1.348 }, { x = 0.376, y = -1.911 }, { x = -0.375, y = -1.907 } } },
   camera = { access = 'rear', triggerRadius = 2.40, standOffset = 1.42, camLocalX = 0.030, camLocalY = -2.897, camLocalZ = 1.328, lookLocalX = 0.064, lookLocalY = -0.863, lookLocalZ = -0.124, fov = 52.0 },
   light = { spots = { { pos = { x = -0.013, y = -1.640, z = 0.944 }, look = { x = -0.024, y = -1.505, z = -0.338 }, color = { r = 255, g = 235, b = 157 }, brightness = 11.50, spotFov = 45.20, distance = 2.70, radius = 12.00, falloff = 10.50 } } },
  },
  bodhi2 = {
   spawn = { x = 0.008, y = -1.831, z = -0.168, areaPoints = { { x = -0.808, y = -1.151 }, { x = -0.523, y = -1.149 }, { x = -0.510, y = -0.858 }, { x = -0.484, y = -0.490 }, { x = -0.174, y = -0.490 }, { x = 0.110, y = -0.491 }, { x = 0.506, y = -0.515 }, { x = 0.512, y = -0.703 }, { x = 0.501, y = -0.924 }, { x = 0.516, y = -1.069 }, { x = 0.511, y = -1.181 }, { x = 0.823, y = -1.174 }, { x = 0.811, y = -1.376 }, { x = 0.817, y = -1.577 }, { x = 0.813, y = -1.981 }, { x = 0.807, y = -2.359 }, { x = 0.806, y = -2.821 }, { x = 0.580, y = -2.836 }, { x = 0.580, y = -2.924 }, { x = 0.374, y = -2.921 }, { x = 0.026, y = -2.917 }, { x = -0.226, y = -2.923 }, { x = -0.580, y = -2.935 }, { x = -0.567, y = -2.845 }, { x = -0.792, y = -2.862 }, { x = -0.805, y = -2.650 }, { x = -0.815, y = -2.405 }, { x = -0.814, y = -2.073 }, { x = -0.813, y = -1.676 } } },
   camera = { access = 'rear', triggerRadius = 2.80, standOffset = 1.70, camLocalX = 0.033, camLocalY = -4.027, camLocalZ = 1.723, lookLocalX = 0.049, lookLocalY = -2.017, lookLocalZ = 0.237, fov = 52.0 },
   light = { spots = { { pos = { x = -0.040, y = -0.427, z = 0.232 }, look = { x = 0.112, y = -4.417, z = -0.218 }, color = { r = 255, g = 255, b = 190 }, brightness = 6.00, spotFov = 52.30, distance = 2.20, radius = 12.00, falloff = 18.00 } } },
  },
  boxville2 = {
   spawn = { x = 0.000, y = -1.827, z = -0.208, areaPoints = { { x = -0.780, y = 0.511 }, { x = 0.802, y = 0.515 }, { x = 0.814, y = -1.773 }, { x = 0.684, y = -2.313 }, { x = 0.692, y = -3.273 }, { x = 0.904, y = -3.257 }, { x = 0.910, y = -3.789 }, { x = -0.852, y = -3.785 }, { x = -0.874, y = -3.263 }, { x = -0.689, y = -3.266 }, { x = -0.672, y = -2.429 }, { x = -0.812, y = -1.785 } } },
   camera = { access = 'rear', triggerRadius = 3.20, standOffset = 2.20, camLocalX = -0.001, camLocalY = -5.295, camLocalZ = 0.730, lookLocalX = 0.014, lookLocalY = -2.833, lookLocalZ = 0.293, fov = 52.0 },
   light = { spots = { { pos = { x = 0.000, y = -3.911, z = 1.008 }, look = { x = 0.000, y = -1.213, z = -0.258 }, color = { r = 255, g = 235, b = 190 }, brightness = 3.90, spotFov = 51.50, distance = 2.20, radius = 12.00, falloff = 18.00 } } },
  },
  brawler = {
   spawn = { x = 0.000, y = -1.810, z = 0.032, areaPoints = { { x = -0.573, y = -1.751 }, { x = -0.494, y = -1.614 }, { x = -0.160, y = -1.638 }, { x = 0.037, y = -1.659 }, { x = 0.261, y = -1.626 }, { x = 0.402, y = -1.610 }, { x = 0.488, y = -1.599 }, { x = 0.557, y = -1.679 }, { x = 0.594, y = -1.816 }, { x = 0.591, y = -1.967 }, { x = 0.576, y = -2.108 }, { x = 0.195, y = -2.133 }, { x = -0.142, y = -2.143 }, { x = -0.366, y = -2.146 }, { x = -0.572, y = -2.122 }, { x = -0.583, y = -1.963 } } },
   camera = { access = 'rear', triggerRadius = 2.80, standOffset = 1.70, camLocalX = 0.003, camLocalY = -2.771, camLocalZ = 0.771, lookLocalX = 0.018, lookLocalY = -0.500, lookLocalZ = -0.275, fov = 52.0 },
   light = { spots = { { pos = { x = 0.024, y = -1.710, z = 1.024 }, look = { x = -0.064, y = -1.684, z = -0.762 }, color = { r = 255, g = 255, b = 255 }, brightness = 6.00, spotFov = 29.30, distance = 2.20, radius = 12.00, falloff = 18.00 } } },
  },
  brioso = {
   spawn = { x = 0.016, y = -1.391, z = 0.296, areaPoints = { { x = -0.368, y = -1.143 }, { x = -0.065, y = -1.158 }, { x = 0.166, y = -1.165 }, { x = 0.370, y = -1.149 }, { x = 0.374, y = -1.560 }, { x = 0.298, y = -1.563 }, { x = 0.130, y = -1.580 }, { x = -0.255, y = -1.568 }, { x = -0.388, y = -1.544 }, { x = -0.372, y = -1.358 } } },
   camera = { access = 'rear', triggerRadius = 2.60, standOffset = 1.60, camLocalX = 0.003, camLocalY = -1.894, camLocalZ = 0.824, lookLocalX = -0.021, lookLocalY = 0.200, lookLocalZ = -0.542, fov = 52.0 },
   light = { spots = { { pos = { x = -0.504, y = -1.243, z = 0.648 }, look = { x = -0.224, y = -1.249, z = 0.246 }, color = { r = 255, g = 235, b = 190 }, brightness = 1.44, spotFov = 47.70, distance = 2.20, radius = 12.00, falloff = 18.00 } } },
  },
  brioso2 = {
   spawn = { x = 0.000, y = -2.019, z = 0.320, areaPoints = { { x = -0.500, y = -1.569 }, { x = -0.150, y = -1.469 }, { x = 0.150, y = -1.469 }, { x = 0.500, y = -1.569 }, { x = 0.580, y = -2.169 }, { x = 0.300, y = -2.769 }, { x = -0.300, y = -2.769 }, { x = -0.580, y = -2.169 } } },
   camera = { access = 'rear', triggerRadius = 2.60, standOffset = 1.60, camLocalX = 0.026, camLocalY = 1.939, camLocalZ = 1.369, lookLocalX = 0.007, lookLocalY = 0.025, lookLocalZ = -0.239, fov = 52.0 },
   light = { spots = { { pos = { x = 0.000, y = -1.919, z = 0.720 }, look = { x = 0.000, y = -2.669, z = 0.270 }, color = { r = 255, g = 235, b = 190 }, brightness = 6.00, spotFov = 12.00, distance = 2.20, radius = 12.00, falloff = 18.00 } } },
  },
  broadway = {
   spawn = { x = 0.000, y = -2.621, z = 0.320, areaPoints = { { x = -0.500, y = -2.171 }, { x = -0.150, y = -2.071 }, { x = 0.150, y = -2.071 }, { x = 0.500, y = -2.171 }, { x = 0.580, y = -2.771 }, { x = 0.300, y = -3.371 }, { x = -0.300, y = -3.371 }, { x = -0.580, y = -2.771 } } },
   camera = { access = 'rear', triggerRadius = 2.50, standOffset = 1.50, camLocalX = 0.000, camLocalY = -3.080, camLocalZ = 0.794, lookLocalX = -0.005, lookLocalY = -0.719, lookLocalZ = -0.028, fov = 52.0 },
   light = { spots = { { pos = { x = 0.000, y = -2.521, z = 0.720 }, look = { x = 0.000, y = -3.271, z = 0.270 }, color = { r = 255, g = 235, b = 190 }, brightness = 6.00, spotFov = 12.00, distance = 2.20, radius = 12.00, falloff = 18.00 } } },
  },
  buccaneer = {
   spawn = { x = 0.000, y = -2.284, z = 0.295, areaPoints = { { x = -0.689, y = -2.085 }, { x = -0.549, y = -2.097 }, { x = -0.531, y = -1.746 }, { x = 0.005, y = -1.784 }, { x = 0.542, y = -1.744 }, { x = 0.534, y = -2.089 }, { x = 0.695, y = -2.108 }, { x = 0.663, y = -2.696 }, { x = 0.093, y = -2.754 }, { x = -0.664, y = -2.695 } } },
   camera = { access = 'rear', triggerRadius = 2.50, standOffset = 1.50, camLocalX = -0.005, camLocalY = -3.297, camLocalZ = 1.362, lookLocalX = 0.071, lookLocalY = -1.404, lookLocalZ = -0.268, fov = 52.0 },
   light = { spots = { { pos = { x = -0.032, y = -2.160, z = 1.143 }, look = { x = -0.008, y = -2.158, z = 0.429 }, color = { r = 255, g = 201, b = 190 }, brightness = 1.30, spotFov = 42.40, distance = 2.20, radius = 12.00, falloff = 18.00 } } },
  },
  buffalo = {
   spawn = { x = 0.000, y = -1.988, z = -0.096, areaPoints = { { x = -0.588, y = -1.610 }, { x = 0.002, y = -1.638 }, { x = 0.574, y = -1.598 }, { x = 0.580, y = -1.882 }, { x = 0.708, y = -1.890 }, { x = 0.556, y = -2.258 }, { x = -0.100, y = -2.274 }, { x = -0.540, y = -2.258 }, { x = -0.716, y = -1.894 }, { x = -0.588, y = -1.880 } } },
   camera = { access = 'rear', triggerRadius = 2.40, standOffset = 1.42, camLocalX = -0.008, camLocalY = -3.430, camLocalZ = 0.913, lookLocalX = 0.002, lookLocalY = -1.237, lookLocalZ = -0.287, fov = 52.0 },
   light = { spots = { { pos = { x = 0.000, y = -2.336, z = 0.520 }, look = { x = 0.000, y = -1.942, z = -0.146 }, color = { r = 255, g = 235, b = 190 }, brightness = 8.60, spotFov = 49.10, distance = 1.60, radius = 12.00, falloff = 18.00 } } },
  },
  buffalo2 = {
   spawn = { x = 0.000, y = -1.972, z = -0.112, areaPoints = { { x = -0.580, y = -1.594 }, { x = 0.018, y = -1.638 }, { x = 0.582, y = -1.590 }, { x = 0.596, y = -1.874 }, { x = 0.740, y = -1.882 }, { x = 0.548, y = -2.250 }, { x = -0.004, y = -2.266 }, { x = -0.564, y = -2.242 }, { x = -0.708, y = -1.886 }, { x = -0.572, y = -1.876 } } },
   camera = { access = 'rear', triggerRadius = 2.40, standOffset = 1.42, camLocalX = -0.019, camLocalY = -3.510, camLocalZ = 0.877, lookLocalX = 0.026, lookLocalY = -1.276, lookLocalZ = -0.244, fov = 52.0 },
   light = { spots = { { pos = { x = 0.000, y = -2.544, z = 0.576 }, look = { x = 0.000, y = -1.790, z = -0.162 }, color = { r = 255, g = 235, b = 190 }, brightness = 4.10, spotFov = 35.40, distance = 2.30, radius = 12.00, falloff = 18.00 } } },
  },
  burrito = {
   spawn = { x = 0.000, y = -1.492, z = -0.304, areaPoints = { { x = -0.940, y = -0.082 }, { x = -0.150, y = -0.094 }, { x = 0.950, y = -0.062 }, { x = 0.924, y = -2.474 }, { x = 0.580, y = -2.474 }, { x = -0.004, y = -2.538 }, { x = -0.980, y = -2.458 }, { x = -0.924, y = -1.274 } } },
   camera = { access = 'rear', triggerRadius = 3.20, standOffset = 1.85, camLocalX = 0.049, camLocalY = -3.404, camLocalZ = 1.061, lookLocalX = 0.058, lookLocalY = -1.326, lookLocalZ = -0.329, fov = 52.0 },
   light = { spots = { { pos = { x = 0.008, y = -0.712, z = 1.136 }, look = { x = 0.000, y = -2.142, z = -0.354 }, color = { r = 255, g = 235, b = 190 }, brightness = 6.00, spotFov = 60.00, distance = 2.20, radius = 12.00, falloff = 18.00 } } },
  },
  casco = {
   camera = { access = 'rear', triggerRadius = 2.45, standOffset = 1.45, camLocalX = 0.015, camLocalY = -2.941, camLocalZ = 1.135, lookLocalX = 0.040, lookLocalY = -0.802, lookLocalZ = -0.158, fov = 52.0 },
  },
  cavalcade = {
   spawn = { x = 0.000, y = -1.907, z = 0.096, areaPoints = { { x = -0.628, y = -1.025 }, { x = 0.650, y = -1.005 }, { x = 0.646, y = -1.757 }, { x = 0.652, y = -2.369 }, { x = -0.004, y = -2.521 }, { x = -0.652, y = -2.345 }, { x = -0.628, y = -1.817 } } },
   camera = { access = 'rear', triggerRadius = 2.90, standOffset = 1.95, camLocalX = 0.015, camLocalY = -4.096, camLocalZ = 1.011, lookLocalX = -0.012, lookLocalY = -1.667, lookLocalZ = 0.421, fov = 52.0 },
   light = { spots = { { pos = { x = 0.000, y = -2.815, z = 1.000 }, look = { x = 0.000, y = -1.837, z = 0.102 }, color = { r = 255, g = 235, b = 190 }, brightness = 14.80, spotFov = 33.50, distance = 2.70, radius = 12.00, falloff = 18.00 } } },
  },
  chino = {
   spawn = { x = 0.000, y = -2.056, z = 0.120, areaPoints = { { x = -0.679, y = -1.639 }, { x = 0.678, y = -1.656 }, { x = 0.670, y = -2.466 }, { x = -0.615, y = -2.482 }, { x = -0.631, y = -2.206 } } },
   camera = { access = 'rear', triggerRadius = 2.50, standOffset = 1.50, camLocalX = 0.096, camLocalY = -3.141, camLocalZ = 1.090, lookLocalX = 0.019, lookLocalY = -1.099, lookLocalZ = -0.351, fov = 52.0 },
   light = { spots = { { pos = { x = 0.000, y = -1.588, z = 0.400 }, look = { x = 0.000, y = -1.778, z = 0.070 }, color = { r = 255, g = 255, b = 190 }, brightness = 3.92, spotFov = 60.00, distance = 2.20, radius = 12.00, falloff = 18.00 } } },
  },
  chino2 = {
   spawn = { x = -0.008, y = -1.999, z = 0.092, areaPoints = { { x = -0.670, y = -1.639 }, { x = 0.669, y = -1.612 }, { x = 0.674, y = -2.149 }, { x = 0.634, y = -2.438 }, { x = -0.683, y = -2.437 }, { x = -0.675, y = -2.149 } } },
   camera = { access = 'rear', triggerRadius = 2.50, standOffset = 1.50, camLocalX = 0.016, camLocalY = -3.208, camLocalZ = 1.537, lookLocalX = 0.005, lookLocalY = -1.532, lookLocalZ = -0.318, fov = 52.0 },
   light = { spots = { { pos = { x = -0.008, y = -1.904, z = 0.916 }, look = { x = -0.008, y = -1.833, z = 0.034 }, color = { r = 255, g = 255, b = 190 }, brightness = 6.00, spotFov = 41.10, distance = 2.20, radius = 12.00, falloff = 18.00 } } },
  },
  clique = {
   spawn = { x = 0.000, y = -2.260, z = 0.035, areaPoints = { { x = -0.601, y = -1.939 }, { x = 0.593, y = -1.948 }, { x = 0.529, y = -2.419 }, { x = 0.006, y = -2.482 }, { x = -0.523, y = -2.419 } } },
   camera = { access = 'rear', triggerRadius = 2.50, standOffset = 1.50, camLocalX = 0.021, camLocalY = -2.941, camLocalZ = 1.209, lookLocalX = 0.053, lookLocalY = -1.325, lookLocalZ = -0.698, fov = 52.0 },
   light = { spots = { { pos = { x = 0.000, y = -1.644, z = 0.435 }, look = { x = 0.000, y = -1.699, z = 0.089 }, color = { r = 255, g = 255, b = 190 }, brightness = 6.00, spotFov = 60.00, distance = 2.20, radius = 12.00, falloff = 18.00 } } },
  },
  club = {
   spawn = { x = 0.000, y = -1.381, z = 0.112, areaPoints = { { x = -0.500, y = -1.235 }, { x = 0.500, y = -1.227 }, { x = 0.516, y = -1.579 }, { x = -0.508, y = -1.579 } } },
   camera = { access = 'rear', triggerRadius = 2.60, standOffset = 1.62, camLocalX = 0.009, camLocalY = -2.236, camLocalZ = 0.899, lookLocalX = 0.009, lookLocalY = -0.104, lookLocalZ = -0.407, fov = 52.0 },
   light = { spots = { { pos = { x = 0.000, y = -1.585, z = 0.392 }, look = { x = 0.000, y = -1.479, z = 0.270 }, color = { r = 255, g = 235, b = 190 }, brightness = 6.00, spotFov = 50.30, distance = 2.20, radius = 12.00, falloff = 18.00 } } },
  },
  cog55 = {
   spawn = { x = 0.000, y = -1.762, z = 0.040, areaPoints = { { x = -0.652, y = -1.576 }, { x = -0.446, y = -1.540 }, { x = -0.458, y = -1.284 }, { x = 0.457, y = -1.296 }, { x = 0.456, y = -1.549 }, { x = 0.648, y = -1.563 }, { x = 0.559, y = -2.074 }, { x = -0.000, y = -2.133 }, { x = -0.551, y = -2.091 } } },
   camera = { access = 'rear', triggerRadius = 2.60, standOffset = 1.55, camLocalX = -0.009, camLocalY = -3.022, camLocalZ = 0.664, lookLocalX = -0.045, lookLocalY = -0.689, lookLocalZ = -0.233, fov = 52.0 },
   light = { spots = { { pos = { x = 0.000, y = -2.142, z = 0.288 }, look = { x = 0.000, y = -1.708, z = -0.018 }, color = { r = 255, g = 235, b = 190 }, brightness = 1.36, spotFov = 60.00, distance = 2.20, radius = 12.00, falloff = 18.00 } } },
  },
  cog552 = {
   spawn = { x = 0.000, y = -2.234, z = 0.003, areaPoints = { { x = -0.518, y = -1.808 }, { x = 0.002, y = -1.812 }, { x = 0.063, y = -1.812 }, { x = 0.521, y = -1.808 }, { x = 0.499, y = -2.369 }, { x = 0.300, y = -2.376 }, { x = -0.300, y = -2.384 }, { x = -0.523, y = -2.384 } } },
   camera = { access = 'rear', triggerRadius = 2.60, standOffset = 1.55, camLocalX = 0.003, camLocalY = -3.332, camLocalZ = 0.778, lookLocalX = 0.015, lookLocalY = -1.080, lookLocalZ = -0.307, fov = 52.0 },
   light = { spots = { { pos = { x = 0.000, y = -1.822, z = 0.403 }, look = { x = 0.000, y = -2.028, z = -0.047 }, color = { r = 255, g = 235, b = 151 }, brightness = 1.52, spotFov = 60.00, distance = 2.20, radius = 12.00, falloff = 18.00 } } },
  },
  cognoscenti = {
   spawn = { x = 0.000, y = -2.471, z = -0.104, areaPoints = { { x = -0.540, y = -2.157 }, { x = 0.540, y = -2.152 }, { x = 0.550, y = -2.708 }, { x = 0.449, y = -2.705 }, { x = 0.289, y = -2.717 }, { x = 0.033, y = -2.726 }, { x = -0.300, y = -2.714 }, { x = -0.549, y = -2.708 } } },
   camera = { access = 'rear', triggerRadius = 2.60, standOffset = 1.55, camLocalX = -0.000, camLocalY = -3.761, camLocalZ = 0.805, lookLocalX = -0.159, lookLocalY = -1.533, lookLocalZ = -0.318, fov = 52.0 },
   light = { spots = { { pos = { x = 0.000, y = -2.123, z = 0.254 }, look = { x = 0.000, y = -2.329, z = -0.099 }, color = { r = 255, g = 235, b = 190 }, brightness = 6.00, spotFov = 60.00, distance = 2.20, radius = 12.00, falloff = 18.00 } } },
  },
  comet2 = {
   spawn = { x = 0.000, y = 1.741, z = -0.160, areaPoints = { { x = -0.244, y = 1.919 }, { x = 0.242, y = 1.923 }, { x = 0.356, y = 1.567 }, { x = -0.340, y = 1.583 } } },
   camera = { access = 'front', triggerRadius = 2.40, standOffset = 1.42, camLocalX = -0.011, camLocalY = 2.714, camLocalZ = 0.901, lookLocalX = -0.049, lookLocalY = 0.867, lookLocalZ = -0.783, fov = 52.0 },
   light = { spots = { { pos = { x = 0.000, y = 2.081, z = 0.440 }, look = { x = 0.000, y = 1.635, z = -0.210 }, color = { r = 255, g = 235, b = 190 }, brightness = 6.00, spotFov = 12.00, distance = 2.20, radius = 12.00, falloff = 18.00 } } },
  },
  contender = {
   camera = { access = 'rear', triggerRadius = 2.90, standOffset = 1.95, camLocalX = 0.012, camLocalY = -2.764, camLocalZ = 0.491, lookLocalX = 0.024, lookLocalY = -0.543, lookLocalZ = -0.657, fov = 52.0 },
  },
  coquette3 = {
   spawn = { x = 0.000, y = -1.732, z = 0.159, areaPoints = { { x = -0.378, y = -1.399 }, { x = 0.390, y = -1.407 }, { x = 0.380, y = -1.963 }, { x = 0.580, y = -1.969 }, { x = 0.537, y = -2.212 }, { x = -0.528, y = -2.194 }, { x = -0.581, y = -1.960 }, { x = -0.382, y = -1.957 } } },
   camera = { access = 'rear', triggerRadius = 2.50, standOffset = 1.50, camLocalX = -0.072, camLocalY = -2.749, camLocalZ = 1.102, lookLocalX = -0.080, lookLocalY = -0.893, lookLocalZ = -0.572, fov = 52.0 },
   light = { spots = { { pos = { x = 0.000, y = -1.376, z = 0.367 }, look = { x = 0.000, y = -1.503, z = 0.109 }, color = { r = 255, g = 255, b = 190 }, brightness = 1.52, spotFov = 58.80, distance = 2.20, radius = 12.00, falloff = 18.00 } } },
  },
  deviant = {
   spawn = { x = 0.000, y = -1.975, z = 0.174, areaPoints = { { x = -0.640, y = -1.891 }, { x = -0.402, y = -1.893 }, { x = -0.396, y = -1.647 }, { x = -0.039, y = -1.677 }, { x = 0.404, y = -1.657 }, { x = 0.397, y = -1.885 }, { x = 0.645, y = -1.892 }, { x = 0.645, y = -2.139 }, { x = 0.145, y = -2.194 }, { x = -0.620, y = -2.141 } } },
   camera = { access = 'rear', triggerRadius = 2.50, standOffset = 1.50, camLocalX = -0.021, camLocalY = -2.717, camLocalZ = 1.243, lookLocalX = 0.017, lookLocalY = -0.977, lookLocalZ = -0.552, fov = 52.0 },
   light = { spots = { { pos = { x = 0.008, y = -1.763, z = 1.054 }, look = { x = -0.032, y = -2.632, z = 0.060 }, color = { r = 255, g = 255, b = 190 }, brightness = 2.26, spotFov = 60.00, distance = 2.20, radius = 12.00, falloff = 18.00 } } },
  },
  dilettante = {
   spawn = { x = 0.000, y = -1.685, z = -0.040, areaPoints = { { x = -0.500, y = -1.379 }, { x = 0.500, y = -1.371 }, { x = 0.492, y = -1.779 }, { x = 0.604, y = -1.843 }, { x = 0.588, y = -1.931 }, { x = 0.004, y = -1.979 }, { x = -0.564, y = -1.931 }, { x = -0.572, y = -1.815 }, { x = -0.496, y = -1.773 } } },
   camera = { access = 'rear', triggerRadius = 2.60, standOffset = 1.69, camLocalX = -0.000, camLocalY = -2.791, camLocalZ = 0.861, lookLocalX = -0.003, lookLocalY = -0.601, lookLocalZ = -0.346, fov = 52.0 },
   light = { spots = { { pos = { x = 0.000, y = -2.097, z = 0.488 }, look = { x = 0.000, y = -1.695, z = -0.018 }, color = { r = 255, g = 235, b = 190 }, brightness = 6.00, spotFov = 32.50, distance = 1.20, radius = 12.00, falloff = 18.00 } } },
  },
  dominator = {
   spawn = { x = 0.000, y = -1.990, z = 0.360, areaPoints = { { x = -0.628, y = -1.732 }, { x = 0.002, y = -1.768 }, { x = 0.638, y = -1.720 }, { x = 0.652, y = -2.308 }, { x = 0.300, y = -2.396 }, { x = -0.236, y = -2.404 }, { x = -0.676, y = -2.316 } } },
   camera = { access = 'rear', triggerRadius = 2.50, standOffset = 1.50, camLocalX = -0.005, camLocalY = -2.982, camLocalZ = 1.392, lookLocalX = -0.009, lookLocalY = -1.012, lookLocalZ = -0.148, fov = 52.0 },
   light = { spots = { { pos = { x = 0.000, y = -2.314, z = 0.760 }, look = { x = 0.000, y = -2.040, z = 0.310 }, color = { r = 255, g = 235, b = 190 }, brightness = 1.90, spotFov = 54.70, distance = 2.20, radius = 12.00, falloff = 18.00 } } },
  },
  drafter = {
   spawn = { x = 0.000, y = -1.706, z = 0.110, areaPoints = { { x = -0.500, y = -1.118 }, { x = -0.150, y = -1.122 }, { x = 0.150, y = -1.122 }, { x = 0.500, y = -1.118 }, { x = 0.500, y = -1.920 }, { x = 0.564, y = -1.919 }, { x = 0.564, y = -2.046 }, { x = 0.531, y = -2.095 }, { x = 0.456, y = -2.119 }, { x = -0.004, y = -2.126 }, { x = -0.468, y = -2.114 }, { x = -0.532, y = -2.086 }, { x = -0.564, y = -2.046 }, { x = -0.568, y = -1.923 }, { x = -0.503, y = -1.919 } } },
   camera = { access = 'rear', triggerRadius = 2.40, standOffset = 1.42, camLocalX = 0.003, camLocalY = -2.787, camLocalZ = 0.716, lookLocalX = -0.005, lookLocalY = -0.480, lookLocalZ = -0.247, fov = 52.0 },
   light = { spots = { { pos = { x = 0.000, y = -1.496, z = 0.432 }, look = { x = -0.008, y = -1.552, z = 0.272 }, color = { r = 255, g = 255, b = 255 }, brightness = 9.50, spotFov = 59.30, distance = 0.80, radius = 59.30, falloff = 23.90 } } },
  },
  dubsta = {
   camera = { access = 'rear', triggerRadius = 2.90, standOffset = 1.95, camLocalX = 0.000, camLocalY = -3.078, camLocalZ = 0.909, lookLocalX = 0.014, lookLocalY = -0.728, lookLocalZ = 0.056, fov = 52.0 },
  },
  dubsta2 = {
   camera = { access = 'rear', triggerRadius = 2.90, standOffset = 1.95, camLocalX = 0.000, camLocalY = -3.078, camLocalZ = 0.909, lookLocalX = 0.014, lookLocalY = -0.728, lookLocalZ = 0.056, fov = 52.0 },
  },
  dukes = {
   spawn = { x = 0.000, y = -2.300, z = -0.048, areaPoints = { { x = -0.540, y = -1.922 }, { x = 0.538, y = -1.934 }, { x = 0.542, y = -2.270 }, { x = 0.804, y = -2.330 }, { x = 0.780, y = -2.754 }, { x = -0.740, y = -2.754 }, { x = -0.772, y = -2.314 }, { x = -0.540, y = -2.298 } } },
   camera = { access = 'rear', triggerRadius = 2.50, standOffset = 1.50, camLocalX = -0.010, camLocalY = -3.373, camLocalZ = 0.954, lookLocalX = 0.008, lookLocalY = -1.303, lookLocalZ = -0.448, fov = 52.0 },
   light = { spots = { { pos = { x = 0.000, y = -2.560, z = 0.464 }, look = { x = 0.000, y = -2.238, z = -0.066 }, color = { r = 255, g = 235, b = 190 }, brightness = 2.60, spotFov = 40.80, distance = 1.10, radius = 12.00, falloff = 18.00 } } },
  },
  elegy = {
   spawn = { x = 0.000, y = -1.670, z = 0.088, areaPoints = { { x = -0.492, y = -1.372 }, { x = -0.006, y = -1.368 }, { x = 0.494, y = -1.368 }, { x = 0.492, y = -1.676 }, { x = 0.660, y = -1.676 }, { x = 0.644, y = -2.044 }, { x = 0.036, y = -2.044 }, { x = -0.648, y = -2.048 }, { x = -0.662, y = -1.666 }, { x = -0.492, y = -1.668 } } },
   camera = { access = 'rear', triggerRadius = 2.40, standOffset = 1.42, camLocalX = 0.019, camLocalY = -2.775, camLocalZ = 0.955, lookLocalX = 0.005, lookLocalY = -0.568, lookLocalZ = -0.220, fov = 52.0 },
   light = { spots = { { pos = { x = 0.000, y = -1.498, z = 0.520 }, look = { x = 0.000, y = -1.600, z = 0.118 }, color = { r = 255, g = 222, b = 190 }, brightness = 6.00, spotFov = 53.30, distance = 2.20, radius = 12.00, falloff = 18.00 } } },
  },
  elegy2 = {
   spawn = { x = 0.000, y = -1.725, z = 0.224, areaPoints = { { x = -0.551, y = -1.351 }, { x = 0.591, y = -1.385 }, { x = 0.516, y = -1.986 }, { x = 0.346, y = -2.084 }, { x = 0.064, y = -2.164 }, { x = -0.219, y = -2.130 }, { x = -0.408, y = -2.021 }, { x = -0.544, y = -1.995 } } },
   camera = { access = 'rear', triggerRadius = 2.40, standOffset = 1.42, camLocalX = -0.018, camLocalY = -2.793, camLocalZ = 1.302, lookLocalX = 0.004, lookLocalY = -0.817, lookLocalZ = -0.228, fov = 52.0 },
   light = { spots = { { pos = { x = -0.008, y = -1.633, z = 0.598 }, look = { x = 0.000, y = -1.615, z = 0.206 }, color = { r = 255, g = 235, b = 190 }, brightness = 6.00, spotFov = 60.00, distance = 2.20, radius = 12.00, falloff = 18.00 } } },
  },
  ellie = {
   spawn = { x = 0.000, y = -1.757, z = -0.120, areaPoints = { { x = -0.484, y = -1.523 }, { x = 0.490, y = -1.519 }, { x = 0.468, y = -2.035 }, { x = -0.468, y = -2.051 } } },
   camera = { access = 'rear', triggerRadius = 2.50, standOffset = 1.50, camLocalX = 0.003, camLocalY = -2.577, camLocalZ = 0.754, lookLocalX = 0.011, lookLocalY = -0.541, lookLocalZ = -0.697, fov = 52.0 },
   light = { spots = { { pos = { x = 0.000, y = -1.993, z = 0.280 }, look = { x = 0.000, y = -1.719, z = -0.170 }, color = { r = 255, g = 235, b = 190 }, brightness = 4.40, spotFov = 55.20, distance = 1.10, radius = 12.00, falloff = 18.00 } } },
  },
  emperor = {
   spawn = { x = 0.000, y = -2.189, z = -0.155, areaPoints = { { x = -0.524, y = -1.687 }, { x = -0.150, y = -1.687 }, { x = 0.150, y = -1.686 }, { x = 0.517, y = -1.691 }, { x = 0.509, y = -2.123 }, { x = 0.825, y = -2.130 }, { x = 0.782, y = -2.661 }, { x = -0.784, y = -2.651 }, { x = -0.819, y = -2.124 }, { x = -0.509, y = -2.118 } } },
   camera = { access = 'rear', triggerRadius = 2.60, standOffset = 1.55, camLocalX = -0.007, camLocalY = -3.738, camLocalZ = 0.901, lookLocalX = 0.006, lookLocalY = -1.478, lookLocalZ = -0.168, fov = 52.0 },
   light = { spots = { { pos = { x = 0.000, y = -1.737, z = 0.421 }, look = { x = 0.000, y = -2.063, z = -0.109 }, color = { r = 255, g = 235, b = 190 }, brightness = 0.72, spotFov = 60.00, distance = 2.20, radius = 12.00, falloff = 18.00 } } },
  },
  entityxf = {
   spawn = { x = 0.000, y = 1.779, z = -0.128, areaPoints = { { x = -0.428, y = 1.837 }, { x = -0.018, y = 1.929 }, { x = 0.420, y = 1.837 }, { x = 0.500, y = 1.533 }, { x = 1.228, y = -4.851 }, { x = -0.524, y = -3.131 }, { x = -0.580, y = 1.629 } } },
   camera = { access = 'front', triggerRadius = 2.35, standOffset = 1.40, camLocalX = 0.037, camLocalY = 2.940, camLocalZ = 0.799, lookLocalX = 0.066, lookLocalY = 0.780, lookLocalZ = -0.458, fov = 52.0 },
  },
  exemplar = {
   spawn = { x = 0.000, y = -2.289, z = 0.011, areaPoints = { { x = -0.524, y = -2.061 }, { x = 0.525, y = -2.063 }, { x = 0.468, y = -2.440 }, { x = 0.337, y = -2.459 }, { x = -0.003, y = -2.501 }, { x = -0.468, y = -2.445 }, { x = -0.486, y = -2.340 }, { x = -0.500, y = -2.203 } } },
   camera = { access = 'rear', triggerRadius = 2.50, standOffset = 1.50, camLocalX = 0.005, camLocalY = -3.020, camLocalZ = 0.643, lookLocalX = 0.001, lookLocalY = -0.879, lookLocalZ = -0.646, fov = 52.0 },
   light = { spots = { { pos = { x = 0.000, y = -2.205, z = 0.286 }, look = { x = 0.000, y = -2.171, z = -0.039 }, color = { r = 255, g = 235, b = 190 }, brightness = 6.00, spotFov = 60.00, distance = 2.20, radius = 12.00, falloff = 18.00 } } },
  },
  f620 = {
   spawn = { x = 0.000, y = -1.536, z = 0.044, areaPoints = { { x = -0.676, y = -1.091 }, { x = -0.150, y = -1.088 }, { x = 0.150, y = -1.084 }, { x = 0.625, y = -1.072 }, { x = 0.556, y = -1.781 }, { x = 0.006, y = -1.843 }, { x = -0.576, y = -1.770 } } },
   camera = { access = 'rear', triggerRadius = 2.50, standOffset = 1.50, camLocalX = 0.010, camLocalY = -2.297, camLocalZ = 0.990, lookLocalX = 0.007, lookLocalY = -0.597, lookLocalZ = -0.843, fov = 52.0 },
   light = { spots = { { pos = { x = 0.000, y = -1.780, z = 0.492 }, look = { x = 0.000, y = -1.442, z = -0.118 }, color = { r = 255, g = 235, b = 190 }, brightness = 1.70, spotFov = 53.70, distance = 1.70, radius = 12.00, falloff = 18.00 } } },
  },
  fbi = {
   camera = { access = 'rear', triggerRadius = 2.67, standOffset = 1.76, camLocalX = 0.038, camLocalY = -2.892, camLocalZ = 0.874, lookLocalX = 0.051, lookLocalY = -0.913, lookLocalZ = -0.653, fov = 52.0 },
  },
  felon = {
   spawn = { x = 0.000, y = -2.137, z = -0.188, areaPoints = { { x = -0.404, y = -1.670 }, { x = 0.400, y = -1.680 }, { x = 0.414, y = -1.977 }, { x = 0.617, y = -1.945 }, { x = 0.574, y = -2.428 }, { x = 0.293, y = -2.481 }, { x = 0.012, y = -2.515 }, { x = -0.302, y = -2.475 }, { x = -0.573, y = -2.431 }, { x = -0.619, y = -1.951 }, { x = -0.418, y = -1.994 } } },
   camera = { access = 'rear', triggerRadius = 2.50, standOffset = 1.50, camLocalX = -0.017, camLocalY = -2.935, camLocalZ = 0.613, lookLocalX = 0.021, lookLocalY = -0.925, lookLocalZ = -0.874, fov = 52.0 },
   light = { spots = { { pos = { x = 0.000, y = -1.781, z = 0.300 }, look = { x = 0.000, y = -1.939, z = -0.238 }, color = { r = 255, g = 235, b = 190 }, brightness = 6.00, spotFov = 60.00, distance = 2.20, radius = 12.00, falloff = 18.00 } } },
  },
  felon2 = {
   spawn = { x = 0.000, y = -2.221, z = -0.110, areaPoints = { { x = -0.623, y = -1.947 }, { x = 0.618, y = -1.947 }, { x = 0.600, y = -2.329 }, { x = 0.005, y = -2.461 }, { x = -0.347, y = -2.386 }, { x = -0.465, y = -2.359 }, { x = -0.561, y = -2.338 }, { x = -0.601, y = -2.330 } } },
   camera = { access = 'rear', triggerRadius = 2.50, standOffset = 1.50, camLocalX = 0.004, camLocalY = -2.884, camLocalZ = 0.610, lookLocalX = -0.016, lookLocalY = -0.973, lookLocalZ = -1.002, fov = 52.0 },
   light = { spots = { { pos = { x = 0.000, y = -2.105, z = 0.346 }, look = { x = -0.004, y = -2.111, z = -0.160 }, color = { r = 255, g = 235, b = 190 }, brightness = 6.00, spotFov = 60.00, distance = 2.20, radius = 12.00, falloff = 18.00 } } },
  },
  feltzer2 = {
   camera = { access = 'rear', triggerRadius = 2.40, standOffset = 1.42, camLocalX = 0.004, camLocalY = 2.907, camLocalZ = 0.705, lookLocalX = -0.110, lookLocalY = 0.865, lookLocalZ = -0.733, fov = 52.0 },
  },
  fq2 = {
   spawn = { x = 0.000, y = -1.600, z = -0.064, areaPoints = { { x = -0.606, y = -1.218 }, { x = 0.598, y = -1.208 }, { x = 0.587, y = -1.786 }, { x = 0.644, y = -1.820 }, { x = 0.624, y = -2.067 }, { x = 0.090, y = -2.096 }, { x = -0.613, y = -2.079 }, { x = -0.652, y = -1.806 }, { x = -0.606, y = -1.791 } } },
   camera = { access = 'rear', triggerRadius = 2.90, standOffset = 1.95, camLocalX = 0.024, camLocalY = -3.139, camLocalZ = 0.932, lookLocalX = 0.010, lookLocalY = -0.865, lookLocalZ = -0.108, fov = 52.0 },
   light = { spots = { { pos = { x = 0.000, y = -2.388, z = 0.744 }, look = { x = 0.000, y = -1.634, z = -0.074 }, color = { r = 255, g = 235, b = 190 }, brightness = 6.00, spotFov = 41.20, distance = 2.20, radius = 12.00, falloff = 18.00 } } },
  },
  fugitive = {
   spawn = { x = 0.000, y = -2.131, z = -0.096, areaPoints = { { x = -0.539, y = -1.813 }, { x = -0.030, y = -1.863 }, { x = 0.027, y = -1.863 }, { x = 0.536, y = -1.808 }, { x = 0.512, y = -2.281 }, { x = 0.418, y = -2.478 }, { x = 0.139, y = -2.541 }, { x = -0.120, y = -2.537 }, { x = -0.412, y = -2.505 }, { x = -0.516, y = -2.263 } } },
   camera = { access = 'rear', triggerRadius = 2.60, standOffset = 1.55, camLocalX = 0.043, camLocalY = -3.177, camLocalZ = 0.494, lookLocalX = -0.035, lookLocalY = -0.825, lookLocalZ = -0.350, fov = 52.0 },
   light = { spots = { { pos = { x = 0.000, y = -1.887, z = 0.224 }, look = { x = 0.000, y = -2.101, z = -0.026 }, color = { r = 255, g = 235, b = 190 }, brightness = 0.72, spotFov = 60.00, distance = 2.20, radius = 12.00, falloff = 18.00 } } },
  },
  fusilade = {
   spawn = { x = 0.000, y = -1.395, z = 0.040, areaPoints = { { x = -0.436, y = -1.041 }, { x = 0.428, y = -1.041 }, { x = 0.420, y = -1.785 }, { x = -0.420, y = -1.793 } } },
   camera = { access = 'rear', triggerRadius = 2.40, standOffset = 1.42, camLocalX = 0.002, camLocalY = -2.484, camLocalZ = 0.737, lookLocalX = -0.018, lookLocalY = -0.359, lookLocalZ = -0.581, fov = 52.0 },
   light = { spots = { { pos = { x = 0.000, y = -1.687, z = 0.648 }, look = { x = 0.000, y = -1.349, z = -0.010 }, color = { r = 255, g = 235, b = 190 }, brightness = 15.90, spotFov = 37.90, distance = 1.40, radius = 12.00, falloff = 18.00 } } },
  },
  futo = {
   spawn = { x = 0.000, y = -1.546, z = 0.016, areaPoints = { { x = -0.444, y = -1.520 }, { x = -0.318, y = -1.348 }, { x = 0.334, y = -1.340 }, { x = 0.404, y = -1.544 }, { x = 0.580, y = -1.576 }, { x = 0.556, y = -1.848 }, { x = -0.556, y = -1.848 }, { x = -0.588, y = -1.544 } } },
   camera = { access = 'rear', triggerRadius = 2.40, standOffset = 1.42, camLocalX = 0.009, camLocalY = -2.639, camLocalZ = 1.150, lookLocalX = -0.004, lookLocalY = -0.718, lookLocalZ = -0.450, fov = 52.0 },
   light = { spots = { { pos = { x = 0.000, y = -1.798, z = 0.656 }, look = { x = 0.064, y = -1.508, z = -0.034 }, color = { r = 255, g = 235, b = 190 }, brightness = 6.00, spotFov = 12.00, distance = 2.20, radius = 12.00, falloff = 18.00 } } },
  },
  gauntlet = {
   spawn = { x = 0.000, y = -1.785, z = 0.032, areaPoints = { { x = -0.644, y = -1.415 }, { x = 0.642, y = -1.403 }, { x = 0.638, y = -1.907 }, { x = 0.844, y = -1.911 }, { x = 0.828, y = -2.247 }, { x = 0.004, y = -2.295 }, { x = -0.820, y = -2.239 }, { x = -0.828, y = -1.919 }, { x = -0.636, y = -1.927 } } },
   camera = { access = 'rear', triggerRadius = 2.50, standOffset = 1.50, camLocalX = 0.001, camLocalY = -3.243, camLocalZ = 1.301, lookLocalX = 0.058, lookLocalY = -1.162, lookLocalZ = -0.084, fov = 52.0 },
   light = { spots = { { pos = { x = 0.000, y = -2.333, z = 0.688 }, look = { x = 0.000, y = -1.707, z = -0.018 }, color = { r = 255, g = 235, b = 190 }, brightness = 6.80, spotFov = 41.30, distance = 1.30, radius = 12.00, falloff = 13.80 } } },
  },
  gauntlet2 = {
   spawn = { x = 0.000, y = -1.952, z = 0.048, areaPoints = { { x = -0.436, y = -1.526 }, { x = 0.434, y = -1.514 }, { x = 0.430, y = -2.082 }, { x = 0.612, y = -2.110 }, { x = 0.604, y = -2.582 }, { x = 0.020, y = -2.622 }, { x = -0.612, y = -2.590 }, { x = -0.604, y = -2.102 }, { x = -0.432, y = -2.086 } } },
   camera = { access = 'rear', triggerRadius = 2.50, standOffset = 1.50, camLocalX = 0.004, camLocalY = -3.223, camLocalZ = 1.254, lookLocalX = -0.001, lookLocalY = -1.224, lookLocalZ = -0.246, fov = 52.0 },
   light = { spots = { { pos = { x = 0.000, y = -2.364, z = 0.680 }, look = { x = 0.000, y = -1.946, z = -0.002 }, color = { r = 255, g = 235, b = 190 }, brightness = 6.00, spotFov = 45.90, distance = 2.20, radius = 12.00, falloff = 18.00 } } },
  },
  glendale = {
   spawn = { x = 0.000, y = -1.886, z = -0.161, areaPoints = { { x = -0.723, y = -1.532 }, { x = -0.400, y = -1.609 }, { x = -0.021, y = -1.636 }, { x = 0.032, y = -1.638 }, { x = 0.362, y = -1.607 }, { x = 0.722, y = -1.539 }, { x = 0.686, y = -2.229 }, { x = 0.300, y = -2.242 }, { x = -0.332, y = -2.244 }, { x = -0.691, y = -2.237 } } },
   camera = { access = 'rear', triggerRadius = 2.60, standOffset = 1.55, camLocalX = 0.000, camLocalY = -2.895, camLocalZ = 0.821, lookLocalX = -0.049, lookLocalY = -0.847, lookLocalZ = -0.612, fov = 52.0 },
   light = { spots = { { pos = { x = -0.750, y = -1.891, z = 0.079 }, look = { x = 0.376, y = -2.152, z = -0.091 }, color = { r = 255, g = 235, b = 190 }, brightness = 1.28, spotFov = 60.00, distance = 2.20, radius = 12.00, falloff = 18.00 } } },
  },
  glendale2 = {
   spawn = { x = 0.000, y = -1.886, z = -0.193, areaPoints = { { x = -0.720, y = -1.747 }, { x = -0.150, y = -1.744 }, { x = 0.150, y = -1.743 }, { x = 0.720, y = -1.744 }, { x = 0.687, y = -2.225 }, { x = 0.300, y = -2.242 }, { x = -0.300, y = -2.251 }, { x = -0.684, y = -2.231 } } },
   camera = { access = 'rear', triggerRadius = 2.60, standOffset = 1.55, camLocalX = 0.000, camLocalY = -2.893, camLocalZ = 0.802, lookLocalX = 0.005, lookLocalY = -0.879, lookLocalZ = -0.678, fov = 52.0 },
   light = { spots = { { pos = { x = 0.000, y = -1.914, z = 0.823 }, look = { x = 0.000, y = -1.856, z = -0.155 }, color = { r = 255, g = 235, b = 190 }, brightness = 2.32, spotFov = 40.30, distance = 2.20, radius = 12.00, falloff = 18.00 } } },
  },
  granger = {
   spawn = { x = 0.000, y = -2.093, z = 0.096, areaPoints = { { x = -0.620, y = -1.067 }, { x = 0.636, y = -1.091 }, { x = 0.636, y = -2.707 }, { x = -0.028, y = -2.731 }, { x = -0.636, y = -2.691 }, { x = -0.636, y = -1.987 } } },
   camera = { access = 'rear', triggerRadius = 2.90, standOffset = 1.95, camLocalX = -0.030, camLocalY = -4.103, camLocalZ = 0.906, lookLocalX = -0.093, lookLocalY = -1.719, lookLocalZ = 0.156, fov = 52.0 },
   light = { spots = { { pos = { x = 0.000, y = -2.969, z = 0.968 }, look = { x = 0.000, y = -2.111, z = 0.046 }, color = { r = 255, g = 235, b = 190 }, brightness = 11.80, spotFov = 39.30, distance = 2.50, radius = 12.00, falloff = 18.00 } } },
  },
  gresley = {
   spawn = { x = 0.000, y = -1.994, z = 0.008, areaPoints = { { x = -0.500, y = -1.384 }, { x = 0.484, y = -1.416 }, { x = 0.524, y = -2.296 }, { x = -0.004, y = -2.352 }, { x = -0.516, y = -2.272 }, { x = -0.492, y = -1.744 } } },
   camera = { access = 'rear', triggerRadius = 2.90, standOffset = 1.95, camLocalX = 0.060, camLocalY = -3.403, camLocalZ = 0.556, lookLocalX = -0.017, lookLocalY = -1.025, lookLocalZ = -0.212, fov = 52.0 },
   light = { spots = { { pos = { x = 0.000, y = -2.598, z = 0.592 }, look = { x = 0.000, y = -1.892, z = -0.042 }, color = { r = 255, g = 235, b = 190 }, brightness = 1.90, spotFov = 38.90, distance = 2.10, radius = 12.00, falloff = 9.10 } } },
  },
  habanero = {
   spawn = { x = 0.000, y = -1.718, z = -0.104, areaPoints = { { x = -0.516, y = -1.268 }, { x = 0.516, y = -1.276 }, { x = 0.532, y = -1.868 }, { x = 0.660, y = -1.884 }, { x = 0.636, y = -2.124 }, { x = 0.012, y = -2.164 }, { x = -0.628, y = -2.116 }, { x = -0.660, y = -1.900 }, { x = -0.516, y = -1.896 } } },
   camera = { access = 'rear', triggerRadius = 2.90, standOffset = 1.95, camLocalX = -0.011, camLocalY = -2.855, camLocalZ = 0.822, lookLocalX = 0.010, lookLocalY = -0.679, lookLocalZ = -0.408, fov = 52.0 },
   light = { spots = { { pos = { x = 0.000, y = -2.186, z = 0.600 }, look = { x = 0.000, y = -1.696, z = -0.154 }, color = { r = 255, g = 235, b = 190 }, brightness = 6.00, spotFov = 37.90, distance = 1.20, radius = 12.00, falloff = 18.00 } } },
  },
  huntley = {
   spawn = { x = 0.000, y = -1.618, z = 0.264, areaPoints = { { x = -0.517, y = -1.376 }, { x = 0.511, y = -1.368 }, { x = 0.508, y = -1.862 }, { x = 0.740, y = -1.864 }, { x = 0.652, y = -2.168 }, { x = -0.028, y = -2.288 }, { x = -0.696, y = -2.132 }, { x = -0.734, y = -1.789 }, { x = -0.510, y = -1.780 } } },
   camera = { access = 'rear', triggerRadius = 2.90, standOffset = 1.95, camLocalX = 0.007, camLocalY = -3.210, camLocalZ = 1.151, lookLocalX = -0.009, lookLocalY = -0.968, lookLocalZ = 0.047, fov = 52.0 },
   light = { spots = { { pos = { x = 0.000, y = -2.430, z = 1.096 }, look = { x = 0.000, y = -1.764, z = 0.318 }, color = { r = 255, g = 247, b = 255 }, brightness = 4.40, spotFov = 33.70, distance = 1.40, radius = 12.00, falloff = 18.00 } } },
  },
  ingot = {
   spawn = { x = 0.000, y = -1.744, z = -0.152, areaPoints = { { x = -0.493, y = -1.429 }, { x = 0.488, y = -1.445 }, { x = 0.487, y = -1.792 }, { x = 0.689, y = -1.795 }, { x = 0.658, y = -2.134 }, { x = 0.039, y = -2.131 }, { x = -0.673, y = -2.118 }, { x = -0.685, y = -1.771 }, { x = -0.486, y = -1.802 } } },
   camera = { access = 'rear', triggerRadius = 2.60, standOffset = 1.55, camLocalX = -0.011, camLocalY = -2.970, camLocalZ = 0.608, lookLocalX = 0.002, lookLocalY = -0.661, lookLocalZ = -0.350, fov = 52.0 },
   light = { spots = { { pos = { x = 0.000, y = -2.212, z = 0.512 }, look = { x = 0.000, y = -1.770, z = -0.138 }, color = { r = 255, g = 235, b = 190 }, brightness = 1.44, spotFov = 60.00, distance = 2.20, radius = 12.00, falloff = 18.00 } } },
  },
  intruder = {
   spawn = { x = -0.017, y = -1.991, z = 0.120, areaPoints = { { x = -0.759, y = -1.693 }, { x = -0.380, y = -1.717 }, { x = 0.334, y = -1.705 }, { x = 0.762, y = -1.697 }, { x = 0.702, y = -2.294 }, { x = 0.283, y = -2.300 }, { x = -0.317, y = -2.308 }, { x = -0.715, y = -2.288 } } },
   camera = { access = 'rear', triggerRadius = 2.60, standOffset = 1.55, camLocalX = 0.029, camLocalY = -2.919, camLocalZ = 1.110, lookLocalX = -0.082, lookLocalY = -0.965, lookLocalZ = -0.445, fov = 52.0 },
   light = { spots = { { pos = { x = -0.017, y = -1.827, z = 0.384 }, look = { x = -0.017, y = -2.113, z = 0.070 }, color = { r = 255, g = 235, b = 190 }, brightness = 2.08, spotFov = 60.00, distance = 2.20, radius = 12.00, falloff = 18.00 } } },
  },
  issi2 = {
   spawn = { x = 0.000, y = -1.383, z = -0.186, areaPoints = { { x = -0.541, y = -1.030 }, { x = 0.531, y = -1.039 }, { x = 0.540, y = -1.200 }, { x = 0.548, y = -1.619 }, { x = 0.308, y = -1.650 }, { x = 0.300, y = -1.648 }, { x = -0.300, y = -1.642 }, { x = -0.558, y = -1.617 } } },
   camera = { access = 'rear', triggerRadius = 2.60, standOffset = 1.60, camLocalX = -0.026, camLocalY = -2.252, camLocalZ = 0.540, lookLocalX = -0.003, lookLocalY = -0.014, lookLocalZ = -0.574, fov = 52.0 },
   light = { spots = { { pos = { x = 0.031, y = -1.116, z = 0.240 }, look = { x = 0.024, y = -1.126, z = -0.242 }, color = { r = 255, g = 235, b = 190 }, brightness = 6.00, spotFov = 60.00, distance = 2.20, radius = 12.00, falloff = 18.00 } } },
  },
  issi3 = {
   spawn = { x = 0.000, y = -1.328, z = 0.063, areaPoints = { { x = -0.339, y = -1.102 }, { x = -0.033, y = -1.102 }, { x = 0.150, y = -1.105 }, { x = 0.335, y = -1.102 }, { x = 0.340, y = -1.514 }, { x = 0.176, y = -1.522 }, { x = -0.009, y = -1.529 }, { x = -0.224, y = -1.520 }, { x = -0.337, y = -1.514 } } },
   camera = { access = 'rear', triggerRadius = 2.60, standOffset = 1.53, camLocalX = -0.020, camLocalY = -2.061, camLocalZ = 0.743, lookLocalX = 0.023, lookLocalY = -0.034, lookLocalZ = -0.721, fov = 52.0 },
   light = { spots = { { pos = { x = 0.000, y = -1.300, z = 0.399 }, look = { x = 0.000, y = -1.050, z = -1.683 }, color = { r = 255, g = 235, b = 190 }, brightness = 6.00, spotFov = 60.00, distance = 2.20, radius = 12.00, falloff = 18.00 } } },
  },
  issi4 = {
   spawn = { x = 0.000, y = -1.321, z = 0.104, areaPoints = { { x = -0.362, y = -1.109 }, { x = -0.150, y = -1.113 }, { x = 0.150, y = -1.113 }, { x = 0.362, y = -1.109 }, { x = 0.350, y = -1.482 }, { x = 0.144, y = -1.491 }, { x = -0.018, y = -1.502 }, { x = -0.156, y = -1.494 }, { x = -0.363, y = -1.468 } } },
   camera = { access = 'rear', triggerRadius = 2.60, standOffset = 1.66, camLocalX = 0.021, camLocalY = -2.069, camLocalZ = 0.725, lookLocalX = -0.025, lookLocalY = 0.020, lookLocalZ = -0.647, fov = 52.0 },
   light = { spots = { { pos = { x = 0.000, y = -1.293, z = 0.376 }, look = { x = 0.000, y = -1.251, z = 0.054 }, color = { r = 255, g = 235, b = 190 }, brightness = 6.00, spotFov = 60.00, distance = 2.20, radius = 12.00, falloff = 18.00 } } },
  },
  issi5 = {
   spawn = { x = 0.000, y = -1.324, z = 0.087, areaPoints = { { x = -0.368, y = -1.103 }, { x = -0.078, y = -1.101 }, { x = 0.150, y = -1.101 }, { x = 0.366, y = -1.105 }, { x = 0.368, y = -1.470 }, { x = 0.142, y = -1.499 }, { x = -0.159, y = -1.497 }, { x = -0.368, y = -1.474 } } },
   camera = { access = 'rear', triggerRadius = 2.60, standOffset = 1.65, camLocalX = -0.010, camLocalY = -2.066, camLocalZ = 0.669, lookLocalX = -0.038, lookLocalY = 0.127, lookLocalZ = -0.533, fov = 52.0 },
   light = { spots = { { pos = { x = 0.000, y = -1.352, z = 0.431 }, look = { x = 0.000, y = -1.230, z = 0.037 }, color = { r = 255, g = 235, b = 190 }, brightness = 6.00, spotFov = 60.00, distance = 2.20, radius = 12.00, falloff = 18.00 } } },
  },
  issi6 = {
   spawn = { x = 0.000, y = -1.314, z = 0.090, areaPoints = { { x = -0.364, y = -1.107 }, { x = -0.150, y = -1.103 }, { x = 0.150, y = -1.103 }, { x = 0.369, y = -1.104 }, { x = 0.364, y = -1.474 }, { x = 0.150, y = -1.498 }, { x = -0.150, y = -1.496 }, { x = -0.364, y = -1.470 } } },
   camera = { access = 'rear', triggerRadius = 2.60, standOffset = 1.66, camLocalX = -0.010, camLocalY = -2.019, camLocalZ = 0.736, lookLocalX = 0.003, lookLocalY = -0.008, lookLocalZ = -0.749, fov = 52.0 },
   light = { spots = { { pos = { x = 0.000, y = -1.214, z = 0.378 }, look = { x = 0.000, y = -1.172, z = 0.040 }, color = { r = 255, g = 235, b = 190 }, brightness = 6.00, spotFov = 60.00, distance = 2.20, radius = 12.00, falloff = 18.00 } } },
  },
  issi8 = {
   camera = { access = 'rear', triggerRadius = 2.90, standOffset = 1.95, camLocalX = 0.003, camLocalY = -2.402, camLocalZ = 0.805, lookLocalX = -0.011, lookLocalY = -0.345, lookLocalZ = -0.616, fov = 52.0 },
  },
  jackal = {
   spawn = { x = 0.000, y = -2.132, z = -0.122, areaPoints = { { x = -0.515, y = -1.838 }, { x = -0.150, y = -1.834 }, { x = 0.150, y = -1.834 }, { x = 0.518, y = -1.835 }, { x = 0.529, y = -2.348 }, { x = 0.008, y = -2.438 }, { x = -0.528, y = -2.348 }, { x = -0.517, y = -2.093 } } },
   camera = { access = 'rear', triggerRadius = 2.50, standOffset = 1.50, camLocalX = 0.012, camLocalY = -2.872, camLocalZ = 0.715, lookLocalX = 0.042, lookLocalY = -0.924, lookLocalZ = -0.852, fov = 52.0 },
   light = { spots = { { pos = { x = 0.000, y = -1.936, z = 0.278 }, look = { x = 0.000, y = -2.030, z = -0.548 }, color = { r = 255, g = 235, b = 190 }, brightness = 6.00, spotFov = 60.00, distance = 2.20, radius = 12.00, falloff = 18.00 } } },
  },
  jugular = {
   spawn = { x = 0.000, y = -2.128, z = 0.144, areaPoints = { { x = -0.548, y = -1.875 }, { x = -0.150, y = -1.923 }, { x = 0.252, y = -1.926 }, { x = 0.524, y = -1.861 }, { x = 0.499, y = -2.278 }, { x = 0.222, y = -2.353 }, { x = -0.300, y = -2.353 }, { x = -0.505, y = -2.278 } } },
   camera = { access = 'rear', triggerRadius = 2.40, standOffset = 1.42, camLocalX = -0.012, camLocalY = -3.077, camLocalZ = 0.830, lookLocalX = 0.038, lookLocalY = -0.766, lookLocalZ = -0.121, fov = 52.0 },
   light = { spots = { { pos = { x = 0.000, y = -1.948, z = 0.633 }, look = { x = 0.000, y = -1.882, z = 0.094 }, color = { r = 255, g = 235, b = 190 }, brightness = 6.00, spotFov = 60.00, distance = 2.20, radius = 12.00, falloff = 18.00 } } },
  },
  kanjo = {
   spawn = { x = 0.000, y = -1.497, z = 0.033, areaPoints = { { x = -0.433, y = -1.145 }, { x = 0.435, y = -1.145 }, { x = 0.434, y = -1.320 }, { x = 0.469, y = -1.614 }, { x = 0.679, y = -1.611 }, { x = 0.653, y = -1.697 }, { x = 0.478, y = -1.769 }, { x = 0.009, y = -1.788 }, { x = -0.476, y = -1.772 }, { x = -0.654, y = -1.695 }, { x = -0.683, y = -1.614 }, { x = -0.466, y = -1.611 }, { x = -0.428, y = -1.303 } } },
   camera = { access = 'rear', triggerRadius = 2.70, standOffset = 1.70, camLocalX = 0.007, camLocalY = -2.441, camLocalZ = 0.849, lookLocalX = -0.005, lookLocalY = -0.307, lookLocalZ = -0.453, fov = 52.0 },
   light = { spots = { { pos = { x = 0.000, y = -1.253, z = 0.881 }, look = { x = 0.000, y = -1.587, z = 0.471 }, color = { r = 255, g = 235, b = 190 }, brightness = 6.00, spotFov = 53.40, distance = 2.20, radius = 12.00, falloff = 18.00 } } },
  },
  kanjosj = {
   spawn = { x = 0.000, y = -1.664, z = 0.276, areaPoints = { { x = -0.450, y = -1.262 }, { x = 0.447, y = -1.264 }, { x = 0.447, y = -1.537 }, { x = 0.647, y = -1.539 }, { x = 0.586, y = -1.994 }, { x = 0.524, y = -2.068 }, { x = 0.057, y = -2.103 }, { x = -0.515, y = -2.068 }, { x = -0.588, y = -1.996 }, { x = -0.643, y = -1.550 }, { x = -0.456, y = -1.542 } } },
   camera = { access = 'rear', triggerRadius = 2.50, standOffset = 1.50, camLocalX = -0.020, camLocalY = -2.681, camLocalZ = 1.195, lookLocalX = -0.005, lookLocalY = -0.735, lookLocalZ = -0.374, fov = 52.0 },
   light = { spots = { { pos = { x = 0.000, y = -1.332, z = 0.589 }, look = { x = 0.000, y = -1.546, z = 0.226 }, color = { r = 255, g = 235, b = 190 }, brightness = 6.00, spotFov = 60.00, distance = 2.20, radius = 12.00, falloff = 18.00 } } },
  },
  khamelion = {
   spawn = { x = 0.000, y = -2.027, z = 0.456, areaPoints = { { x = -0.436, y = -1.585 }, { x = 0.474, y = -1.581 }, { x = 0.462, y = -1.861 }, { x = 0.548, y = -1.873 }, { x = 0.516, y = -2.297 }, { x = 0.012, y = -2.337 }, { x = -0.532, y = -2.313 }, { x = -0.564, y = -1.889 }, { x = -0.460, y = -1.881 } } },
   camera = { access = 'rear', triggerRadius = 2.40, standOffset = 1.42, camLocalX = -0.006, camLocalY = -3.311, camLocalZ = 1.433, lookLocalX = -0.018, lookLocalY = -1.327, lookLocalZ = -0.088, fov = 52.0 },
   light = { spots = { { pos = { x = 0.000, y = -2.335, z = 1.192 }, look = { x = 0.000, y = -1.885, z = 0.406 }, color = { r = 255, g = 235, b = 190 }, brightness = 12.10, spotFov = 30.80, distance = 1.60, radius = 12.00, falloff = 18.00 } } },
  },
  landstalker = {
   spawn = { x = 0.000, y = -1.957, z = 0.256, areaPoints = { { x = -0.500, y = -1.211 }, { x = 0.498, y = -1.215 }, { x = 0.502, y = -2.079 }, { x = 0.820, y = -2.075 }, { x = 0.860, y = -2.387 }, { x = 0.300, y = -2.475 }, { x = -0.436, y = -2.475 }, { x = -0.860, y = -2.379 }, { x = -0.832, y = -2.091 }, { x = -0.506, y = -2.075 } } },
   camera = { access = 'rear', triggerRadius = 2.90, standOffset = 1.95, camLocalX = 0.001, camLocalY = -3.477, camLocalZ = 1.053, lookLocalX = 0.010, lookLocalY = -1.181, lookLocalZ = 0.063, fov = 52.0 },
   light = { spots = { { pos = { x = 0.000, y = -3.009, z = 1.232 }, look = { x = 0.000, y = -1.927, z = 0.262 }, color = { r = 255, g = 235, b = 190 }, brightness = 0.50, spotFov = 34.90, distance = 2.20, radius = 12.00, falloff = 18.00 } } },
  },
  landstalker2 = {
   camera = { access = 'rear', triggerRadius = 2.90, standOffset = 1.95, camLocalX = -0.000, camLocalY = -3.388, camLocalZ = 1.087, lookLocalX = 0.003, lookLocalY = -1.090, lookLocalZ = 0.103, fov = 52.0 },
  },
  mesa = {
   spawn = { x = 0.000, y = -1.655, z = 0.192, areaPoints = { { x = -0.524, y = -1.293 }, { x = -0.038, y = -1.297 }, { x = 0.206, y = -1.305 }, { x = 0.516, y = -1.301 }, { x = 0.516, y = -2.029 }, { x = 0.068, y = -2.037 }, { x = -0.500, y = -2.021 }, { x = -0.508, y = -1.805 } } },
   camera = { access = 'rear', triggerRadius = 2.90, standOffset = 1.95, camLocalX = 0.117, camLocalY = -2.684, camLocalZ = 0.757, lookLocalX = -0.046, lookLocalY = -0.423, lookLocalZ = -0.297, fov = 52.0 },
   light = { spots = { { pos = { x = 0.000, y = -1.555, z = 1.200 }, look = { x = 0.000, y = -1.625, z = 0.142 }, color = { r = 255, g = 235, b = 190 }, brightness = 6.00, spotFov = 34.70, distance = 2.20, radius = 12.00, falloff = 18.00 } } },
  },
  mesa2 = {
   camera = { access = 'rear', triggerRadius = 2.90, standOffset = 1.95, camLocalX = 0.117, camLocalY = -2.684, camLocalZ = 0.757, lookLocalX = -0.046, lookLocalY = -0.423, lookLocalZ = -0.297, fov = 52.0 },
  },
  mule2 = {
   spawn = { x = 0.000, y = -1.530, z = -0.104, areaPoints = { { x = -1.247, y = 1.639 }, { x = 1.219, y = 1.618 }, { x = 1.227, y = -3.637 }, { x = -1.230, y = -3.629 } } },
   camera = { access = 'rear', triggerRadius = 3.40, standOffset = 2.40, camLocalX = 0.150, camLocalY = -5.004, camLocalZ = 1.945, lookLocalX = 0.180, lookLocalY = -2.854, lookLocalZ = 0.669, fov = 52.0 },
  },
  ninef = {
   spawn = { x = 0.000, y = 1.936, z = -0.008, areaPoints = { { x = -0.388, y = 1.970 }, { x = -0.150, y = 1.974 }, { x = 0.150, y = 1.982 }, { x = 0.388, y = 1.962 }, { x = 0.452, y = 1.546 }, { x = 0.100, y = 1.514 }, { x = -0.220, y = 1.522 }, { x = -0.452, y = 1.538 } } },
   camera = { access = 'front', triggerRadius = 2.40, standOffset = 1.42, camLocalX = 0.001, camLocalY = 2.466, camLocalZ = 0.797, lookLocalX = -0.058, lookLocalY = 0.649, lookLocalZ = -0.919, fov = 52.0 },
   light = { spots = { { pos = { x = 0.000, y = 1.980, z = -0.032 }, look = { x = 0.000, y = 1.854, z = -0.018 }, color = { r = 255, g = 235, b = 190 }, brightness = 6.00, spotFov = 60.00, distance = 2.20, radius = 12.00, falloff = 18.00 } } },
  },
  ninef2 = {
   spawn = { x = 0.000, y = -2.099, z = 0.320, areaPoints = { { x = -0.500, y = -1.649 }, { x = -0.150, y = -1.549 }, { x = 0.150, y = -1.549 }, { x = 0.500, y = -1.649 }, { x = 0.580, y = -2.249 }, { x = 0.300, y = -2.849 }, { x = -0.300, y = -2.849 } } },
   camera = { access = 'rear', triggerRadius = 2.40, standOffset = 1.42, camLocalX = -1.843, camLocalY = -3.771, camLocalZ = 1.452, lookLocalX = -0.507, lookLocalY = -2.026, lookLocalZ = 0.261, fov = 52.0 },
   light = { spots = { { pos = { x = 0.000, y = -1.999, z = 0.720 }, look = { x = 0.000, y = -2.749, z = 0.270 }, color = { r = 255, g = 235, b = 190 }, brightness = 6.00, spotFov = 12.00, distance = 2.20, radius = 12.00, falloff = 18.00 } } },
  },
  novak = {
   camera = { access = 'rear', triggerRadius = 2.90, standOffset = 1.95, camLocalX = 0.002, camLocalY = -2.925, camLocalZ = 0.892, lookLocalX = 0.010, lookLocalY = -0.646, lookLocalZ = -0.136, fov = 52.0 },
  },
  omnisegt = {
   spawn = { x = 0.000, y = -1.927, z = 0.064, areaPoints = { { x = -0.492, y = -1.637 }, { x = 0.490, y = -1.641 }, { x = 0.502, y = -1.929 }, { x = 0.780, y = -1.941 }, { x = 0.724, y = -2.173 }, { x = 0.292, y = -2.253 }, { x = -0.300, y = -2.245 }, { x = -0.748, y = -2.173 }, { x = -0.748, y = -1.953 }, { x = -0.508, y = -1.923 } } },
   camera = { access = 'rear', triggerRadius = 2.40, standOffset = 1.42, camLocalX = -0.010, camLocalY = -3.296, camLocalZ = 0.944, lookLocalX = 0.067, lookLocalY = -1.129, lookLocalZ = -0.301, fov = 52.0 },
   light = { spots = { { pos = { x = 0.000, y = -2.363, z = 0.464 }, look = { x = 0.000, y = -1.873, z = 0.014 }, color = { r = 255, g = 235, b = 190 }, brightness = 10.60, spotFov = 45.70, distance = 1.90, radius = 12.00, falloff = 18.00 } } },
  },
  oracle = {
   spawn = { x = 0.000, y = -2.182, z = 0.218, areaPoints = { { x = -0.504, y = -1.630 }, { x = 0.513, y = -1.639 }, { x = 0.510, y = -2.119 }, { x = 0.752, y = -2.114 }, { x = 0.691, y = -2.465 }, { x = 0.453, y = -2.553 }, { x = 0.264, y = -2.586 }, { x = -0.027, y = -2.597 }, { x = -0.266, y = -2.590 }, { x = -0.465, y = -2.551 }, { x = -0.692, y = -2.460 }, { x = -0.753, y = -2.106 }, { x = -0.509, y = -2.112 }, { x = -0.509, y = -1.881 } } },
   camera = { access = 'rear', triggerRadius = 2.50, standOffset = 1.50, camLocalX = 0.022, camLocalY = -3.044, camLocalZ = 1.062, lookLocalX = 0.015, lookLocalY = -1.036, lookLocalZ = -0.427, fov = 52.0 },
   light = { spots = { { pos = { x = 0.000, y = -2.081, z = 0.723 }, look = { x = 0.000, y = -2.039, z = 0.234 }, color = { r = 255, g = 235, b = 190 }, brightness = 6.00, spotFov = 60.00, distance = 2.20, radius = 12.00, falloff = 18.00 } } },
  },
  panto = {
   spawn = { x = 0.008, y = -0.946, z = 0.360, areaPoints = { { x = -0.500, y = -0.728 }, { x = 0.500, y = -0.744 }, { x = 0.484, y = -1.216 }, { x = -0.452, y = -1.200 } } },
   camera = { access = 'rear', triggerRadius = 2.60, standOffset = 1.51, camLocalX = 0.012, camLocalY = -2.022, camLocalZ = 0.955, lookLocalX = 0.004, lookLocalY = 0.267, lookLocalZ = -0.049, fov = 52.0 },
   light = { spots = { { pos = { x = -0.008, y = -1.190, z = 0.664 }, look = { x = 0.008, y = -0.844, z = 0.366 }, color = { r = 255, g = 235, b = 190 }, brightness = 2.60, spotFov = 49.30, distance = 1.80, radius = 12.00, falloff = 18.00 } } },
  },
  patriot = {
   spawn = { x = 0.000, y = -1.945, z = 0.176, areaPoints = { { x = -0.612, y = -1.495 }, { x = 0.618, y = -1.475 }, { x = 0.614, y = -2.163 }, { x = 0.876, y = -2.175 }, { x = 0.900, y = -2.391 }, { x = -0.900, y = -2.383 }, { x = -0.884, y = -2.159 }, { x = -0.620, y = -2.167 } } },
   camera = { access = 'rear', triggerRadius = 2.90, standOffset = 1.95, camLocalX = 0.027, camLocalY = -3.293, camLocalZ = 0.896, lookLocalX = -0.086, lookLocalY = -0.932, lookLocalZ = 0.084, fov = 52.0 },
   light = { spots = { { pos = { x = 0.000, y = -2.693, z = 0.824 }, look = { x = 0.000, y = -1.875, z = 0.118 }, color = { r = 255, g = 235, b = 190 }, brightness = 3.30, spotFov = 51.90, distance = 1.50, radius = 12.00, falloff = 18.00 } } },
  },
  patriot2 = {
   camera = { access = 'rear', triggerRadius = 2.90, standOffset = 1.95, camLocalX = 0.007, camLocalY = -4.056, camLocalZ = 0.907, lookLocalX = 0.022, lookLocalY = -1.650, lookLocalZ = 0.226, fov = 52.0 },
  },
  penumbra2 = {
   spawn = { x = 0.000, y = -1.656, z = 0.352, areaPoints = { { x = -0.588, y = -1.334 }, { x = 0.610, y = -1.330 }, { x = 0.548, y = -1.982 }, { x = 0.140, y = -2.038 }, { x = -0.100, y = -2.030 }, { x = -0.540, y = -1.982 }, { x = -0.564, y = -1.614 } } },
   camera = { access = 'rear', triggerRadius = 2.40, standOffset = 1.42, camLocalX = -0.003, camLocalY = -2.904, camLocalZ = 1.291, lookLocalX = 0.010, lookLocalY = -0.879, lookLocalZ = -0.174, fov = 52.0 },
   light = { spots = { { pos = { x = 0.000, y = -2.036, z = 0.976 }, look = { x = -0.024, y = -1.594, z = 0.302 }, color = { r = 255, g = 235, b = 190 }, brightness = 9.80, spotFov = 43.70, distance = 1.20, radius = 12.00, falloff = 18.00 } } },
  },
  police3 = {
   spawn = { x = 0.000, y = -1.918, z = -0.088, areaPoints = { { x = -0.500, y = -1.476 }, { x = 0.490, y = -1.456 }, { x = 0.500, y = -2.084 }, { x = 0.636, y = -2.124 }, { x = 0.564, y = -2.340 }, { x = -0.012, y = -2.396 }, { x = -0.568, y = -2.328 }, { x = -0.606, y = -2.206 }, { x = -0.492, y = -2.148 } } },
   camera = { access = 'rear', triggerRadius = 2.72, standOffset = 1.79, camLocalX = 0.033, camLocalY = -3.063, camLocalZ = 0.443, lookLocalX = -0.007, lookLocalY = -0.660, lookLocalZ = -0.247, fov = 52.0 },
   light = { spots = { { pos = { x = 0.000, y = -2.410, z = 0.312 }, look = { x = 0.000, y = -1.936, z = -0.138 }, color = { r = 255, g = 235, b = 190 }, brightness = 6.00, spotFov = 55.40, distance = 1.60, radius = 12.00, falloff = 18.00 } } },
  },
  postlude = {
   spawn = { x = 0.000, y = -1.587, z = 0.121, areaPoints = { { x = -0.461, y = -1.262 }, { x = -0.150, y = -1.295 }, { x = 0.150, y = -1.289 }, { x = 0.458, y = -1.271 }, { x = 0.463, y = -1.542 }, { x = 0.721, y = -1.529 }, { x = 0.696, y = -1.861 }, { x = 0.300, y = -1.878 }, { x = -0.300, y = -1.881 }, { x = -0.704, y = -1.857 }, { x = -0.718, y = -1.533 }, { x = -0.469, y = -1.530 } } },
   camera = { access = 'rear', triggerRadius = 2.50, standOffset = 1.50, camLocalX = 0.030, camLocalY = -2.338, camLocalZ = 1.181, lookLocalX = -0.003, lookLocalY = -0.604, lookLocalZ = -0.620, fov = 52.0 },
   light = { spots = { { pos = { x = 0.000, y = -1.322, z = 0.443 }, look = { x = 0.000, y = -1.394, z = 0.142 }, color = { r = 255, g = 235, b = 190 }, brightness = 6.00, spotFov = 60.00, distance = 2.20, radius = 12.00, falloff = 18.00 } } },
  },
  prairie = {
   spawn = { x = 0.000, y = -1.537, z = -0.106, areaPoints = { { x = -0.486, y = -1.059 }, { x = -0.150, y = -1.071 }, { x = 0.150, y = -1.077 }, { x = 0.488, y = -1.087 }, { x = 0.439, y = -1.828 }, { x = 0.288, y = -1.874 }, { x = 0.003, y = -1.891 }, { x = -0.288, y = -1.870 }, { x = -0.436, y = -1.822 } } },
   camera = { access = 'rear', triggerRadius = 2.60, standOffset = 1.69, camLocalX = -0.006, camLocalY = -2.599, camLocalZ = 0.679, lookLocalX = 0.018, lookLocalY = -0.458, lookLocalZ = -0.611, fov = 52.0 },
   light = { spots = { { pos = { x = 0.000, y = -1.389, z = 0.390 }, look = { x = 0.000, y = -1.307, z = -0.156 }, color = { r = 255, g = 235, b = 190 }, brightness = 6.00, spotFov = 60.00, distance = 2.20, radius = 12.00, falloff = 18.00 } } },
  },
  premier = {
   spawn = { x = 0.000, y = -1.946, z = 0.182, areaPoints = { { x = -0.584, y = -1.743 }, { x = -0.014, y = -1.812 }, { x = 0.572, y = -1.741 }, { x = 0.556, y = -2.056 }, { x = 0.008, y = -2.132 }, { x = -0.539, y = -2.084 }, { x = -0.614, y = -1.991 } } },
   camera = { access = 'rear', triggerRadius = 2.60, standOffset = 1.55, camLocalX = 0.019, camLocalY = -2.781, camLocalZ = 0.960, lookLocalX = -0.007, lookLocalY = -0.622, lookLocalZ = -0.300, fov = 52.0 },
   light = { spots = { { pos = { x = 0.000, y = -2.230, z = 0.606 }, look = { x = 0.000, y = -1.940, z = 0.220 }, color = { r = 255, g = 235, b = 190 }, brightness = 2.10, spotFov = 54.20, distance = 1.50, radius = 12.00, falloff = 18.00 } } },
  },
  previon = {
   spawn = { x = 0.000, y = -2.025, z = -0.089, areaPoints = { { x = -0.395, y = -1.563 }, { x = -0.213, y = -1.619 }, { x = -0.012, y = -1.649 }, { x = 0.184, y = -1.621 }, { x = 0.386, y = -1.569 }, { x = 0.393, y = -1.764 }, { x = 0.652, y = -1.762 }, { x = 0.592, y = -2.238 }, { x = 0.339, y = -2.268 }, { x = 0.015, y = -2.280 }, { x = -0.300, y = -2.272 }, { x = -0.568, y = -2.235 }, { x = -0.657, y = -1.761 }, { x = -0.394, y = -1.755 } } },
   camera = { access = 'rear', triggerRadius = 2.50, standOffset = 1.50, camLocalX = 0.006, camLocalY = -2.684, camLocalZ = 0.919, lookLocalX = 0.056, lookLocalY = -1.078, lookLocalZ = -0.996, fov = 52.0 },
   light = { spots = { { pos = { x = 0.000, y = -1.709, z = 0.223 }, look = { x = 0.000, y = -1.787, z = -0.054 }, color = { r = 255, g = 235, b = 190 }, brightness = 6.00, spotFov = 60.00, distance = 2.20, radius = 12.00, falloff = 18.00 } } },
  },
  primo = {
   spawn = { x = 0.000, y = -1.971, z = -0.046, areaPoints = { { x = -0.580, y = -1.639 }, { x = -0.150, y = -1.629 }, { x = 0.150, y = -1.623 }, { x = 0.584, y = -1.628 }, { x = 0.610, y = -1.918 }, { x = 0.767, y = -1.908 }, { x = 0.697, y = -2.342 }, { x = 0.004, y = -2.405 }, { x = -0.684, y = -2.337 }, { x = -0.768, y = -1.916 }, { x = -0.610, y = -1.902 } } },
   camera = { access = 'rear', triggerRadius = 2.60, standOffset = 1.55, camLocalX = 0.030, camLocalY = -3.235, camLocalZ = 0.924, lookLocalX = -0.039, lookLocalY = -1.010, lookLocalZ = -0.214, fov = 52.0 },
   light = { spots = { { pos = { x = 0.000, y = -1.719, z = 0.354 }, look = { x = 0.000, y = -1.909, z = -0.096 }, color = { r = 255, g = 235, b = 190 }, brightness = 2.72, spotFov = 60.00, distance = 2.20, radius = 12.00, falloff = 18.00 } } },
  },
  primo2 = {
   spawn = { x = 0.000, y = -2.154, z = 0.087, areaPoints = { { x = -0.554, y = -1.633 }, { x = -0.150, y = -1.636 }, { x = 0.150, y = -1.632 }, { x = 0.544, y = -1.623 }, { x = 0.550, y = -2.006 }, { x = 0.755, y = -1.994 }, { x = 0.696, y = -2.417 }, { x = 0.004, y = -2.480 }, { x = -0.692, y = -2.416 }, { x = -0.754, y = -2.009 }, { x = -0.548, y = -2.009 } } },
   camera = { access = 'rear', triggerRadius = 2.60, standOffset = 1.55, camLocalX = 0.017, camLocalY = -3.232, camLocalZ = 0.880, lookLocalX = -0.018, lookLocalY = -0.932, lookLocalZ = -0.101, fov = 52.0 },
   light = { spots = { { pos = { x = 0.000, y = -1.710, z = 0.423 }, look = { x = 0.000, y = -1.868, z = 0.149 }, color = { r = 255, g = 235, b = 190 }, brightness = 0.34, spotFov = 60.00, distance = 2.20, radius = 12.00, falloff = 18.00 } } },
  },
  radi = {
   camera = { access = 'rear', triggerRadius = 2.90, standOffset = 1.95, camLocalX = 0.004, camLocalY = -2.962, camLocalZ = 0.931, lookLocalX = -0.009, lookLocalY = -0.698, lookLocalZ = -0.130, fov = 52.0 },
  },
  rebla = {
   camera = { access = 'rear', triggerRadius = 3.00, standOffset = 1.85, rearDistance = 0.56, rearHeight = 0.78, lookHeight = 0.66 },
  },
  regina = {
   camera = { access = 'rear', triggerRadius = 2.60, standOffset = 1.55, camLocalX = -0.001, camLocalY = -3.509, camLocalZ = 0.905, lookLocalX = -0.003, lookLocalY = -1.455, lookLocalZ = -0.521, fov = 52.0 },
  },
  remus = {
   spawn = { x = -0.024, y = -1.780, z = 0.264, areaPoints = { { x = -0.500, y = -1.382 }, { x = 0.474, y = -1.402 }, { x = 0.494, y = -1.594 }, { x = 0.684, y = -1.574 }, { x = 0.620, y = -2.062 }, { x = -0.092, y = -2.110 }, { x = -0.644, y = -2.070 }, { x = -0.644, y = -1.558 } } },
   camera = { access = 'rear', triggerRadius = 2.40, standOffset = 1.45, camLocalX = 0.004, camLocalY = -2.600, camLocalZ = 1.422, lookLocalX = 0.097, lookLocalY = -0.941, lookLocalZ = -0.445, fov = 52.0 },
   light = { spots = { { pos = { x = 0.008, y = -1.522, z = 0.544 }, look = { x = 0.000, y = -1.618, z = 0.392 }, color = { r = 255, g = 235, b = 190 }, brightness = 5.05, spotFov = 60.00, distance = 2.20, radius = 12.00, falloff = 18.00 } } },
  },
  rhapsody = {
   spawn = { x = -0.016, y = -1.585, z = -0.104, areaPoints = { { x = -0.580, y = -1.189 }, { x = -0.126, y = -1.194 }, { x = 0.589, y = -1.211 }, { x = 0.573, y = -1.948 }, { x = -0.586, y = -1.949 } } },
   camera = { access = 'rear', triggerRadius = 2.60, standOffset = 1.66, camLocalX = -0.011, camLocalY = -2.552, camLocalZ = 0.589, lookLocalX = 0.016, lookLocalY = -0.350, lookLocalZ = -0.595, fov = 52.0 },
   light = { spots = { { pos = { x = -0.008, y = -1.973, z = 1.128 }, look = { x = -0.016, y = -1.531, z = -0.090 }, color = { r = 255, g = 235, b = 190 }, brightness = 1.68, spotFov = 25.90, distance = 2.20, radius = 12.00, falloff = 18.00 } } },
  },
  rhinehart = {
   camera = { access = 'rear', triggerRadius = 2.60, standOffset = 1.55, camLocalX = -0.003, camLocalY = -2.863, camLocalZ = 0.678, lookLocalX = -0.033, lookLocalY = -0.781, lookLocalZ = -0.707, fov = 52.0 },
  },
  rocoto = {
   spawn = { x = -0.016, y = -1.707, z = -0.168, areaPoints = { { x = -0.500, y = -1.145 }, { x = 0.506, y = -1.117 }, { x = 0.510, y = -1.557 }, { x = 0.628, y = -1.617 }, { x = 0.604, y = -2.025 }, { x = 0.300, y = -2.129 }, { x = -0.300, y = -2.137 }, { x = -0.612, y = -1.993 }, { x = -0.604, y = -1.721 }, { x = -0.504, y = -1.641 } } },
   camera = { access = 'rear', triggerRadius = 2.90, standOffset = 1.95, camLocalX = 0.049, camLocalY = -3.095, camLocalZ = 0.618, lookLocalX = 0.043, lookLocalY = -0.774, lookLocalZ = -0.311, fov = 52.0 },
   light = { spots = { { pos = { x = 0.000, y = -2.031, z = 0.584 }, look = { x = 0.000, y = -1.701, z = -0.218 }, color = { r = 255, g = 235, b = 190 }, brightness = 6.00, spotFov = 40.10, distance = 1.20, radius = 12.00, falloff = 18.00 } } },
  },
  rumpo = {
   spawn = { x = 0.000, y = -2.537, z = 0.320, areaPoints = { { x = -0.500, y = -2.087 }, { x = -0.150, y = -1.987 }, { x = 0.150, y = -1.987 }, { x = 0.500, y = -2.087 }, { x = 0.580, y = -2.687 }, { x = 0.300, y = -3.287 }, { x = -0.300, y = -3.287 }, { x = -0.580, y = -2.687 } } },
   camera = { mode = 'van', triggerRadius = 3.2, standOffset = 1.85, rearDistance = 0.6, rearHeight = 0.9, lookHeight = 0.46 },
   light = { spots = { { pos = { x = 0.000, y = -2.437, z = 0.720 }, look = { x = 0.000, y = -3.187, z = 0.270 }, color = { r = 255, g = 235, b = 190 }, brightness = 6.00, spotFov = 12.00, distance = 2.20, radius = 12.00, falloff = 18.00 } } },
  },
  sabregt = {
   spawn = { x = 0.000, y = -2.052, z = -0.000, areaPoints = { { x = -0.500, y = -1.498 }, { x = 0.498, y = -1.478 }, { x = 0.502, y = -1.982 }, { x = 0.676, y = -1.970 }, { x = 0.684, y = -2.394 }, { x = -0.676, y = -2.402 }, { x = -0.676, y = -1.994 }, { x = -0.492, y = -1.978 } } },
   camera = { access = 'rear', triggerRadius = 2.50, standOffset = 1.50, camLocalX = 0.001, camLocalY = -3.404, camLocalZ = 0.880, lookLocalX = -0.003, lookLocalY = -1.166, lookLocalZ = -0.234, fov = 52.0 },
   light = { spots = { { pos = { x = 0.000, y = -2.328, z = 0.496 }, look = { x = 0.000, y = -1.990, z = -0.050 }, color = { r = 255, g = 235, b = 190 }, brightness = 1.30, spotFov = 51.80, distance = 2.10, radius = 12.00, falloff = 18.00 } } },
  },
  sandking = {
   camera = { triggerRadius = 3.0, standOffset = 1.8, rearDistance = 0.62, rearHeight = 0.96, lookHeight = 0.5 },
  },
  schafter2 = {
   spawn = { x = 0.000, y = -1.866, z = -0.048, areaPoints = { { x = -0.452, y = -1.320 }, { x = 0.458, y = -1.316 }, { x = 0.470, y = -1.972 }, { x = 0.724, y = -1.984 }, { x = 0.636, y = -2.512 }, { x = -0.020, y = -2.624 }, { x = -0.556, y = -2.576 }, { x = -0.684, y = -2.376 }, { x = -0.736, y = -1.976 }, { x = -0.450, y = -1.976 } } },
   camera = { access = 'rear', triggerRadius = 2.60, standOffset = 1.55, camLocalX = 0.002, camLocalY = -3.383, camLocalZ = 0.740, lookLocalX = -0.014, lookLocalY = -1.083, lookLocalZ = -0.239, fov = 52.0 },
   light = { spots = { { pos = { x = 0.000, y = -2.638, z = 0.376 }, look = { x = 0.000, y = -1.620, z = -0.098 }, color = { r = 255, g = 235, b = 190 }, brightness = 15.90, spotFov = 53.20, distance = 1.90, radius = 12.00, falloff = 18.00 } } },
  },
  schafter3 = {
   spawn = { x = 0.000, y = -1.382, z = 0.040, areaPoints = { { x = -0.388, y = -1.204 }, { x = 0.410, y = -1.200 }, { x = 0.398, y = -1.552 }, { x = 0.516, y = -1.612 }, { x = 0.460, y = -1.988 }, { x = 0.004, y = -2.012 }, { x = -0.436, y = -2.004 }, { x = -0.500, y = -1.596 }, { x = -0.396, y = -1.536 } } },
   camera = { access = 'rear', triggerRadius = 2.40, standOffset = 1.42, camLocalX = -0.001, camLocalY = -2.988, camLocalZ = 0.951, lookLocalX = 0.035, lookLocalY = -0.761, lookLocalZ = -0.185, fov = 52.0 },
   light = { spots = { { pos = { x = 0.000, y = -1.890, z = 0.656 }, look = { x = 0.000, y = -1.432, z = -0.010 }, color = { r = 255, g = 235, b = 190 }, brightness = 2.20, spotFov = 40.30, distance = 2.30, radius = 12.00, falloff = 18.00 } } },
  },
  schwarzer = {
   spawn = { x = 0.000, y = -2.123, z = 0.256, areaPoints = { { x = -0.412, y = -1.777 }, { x = 0.434, y = -1.765 }, { x = 0.422, y = -2.037 }, { x = 0.444, y = -2.361 }, { x = -0.052, y = -2.401 }, { x = -0.428, y = -2.361 }, { x = -0.420, y = -2.105 } } },
   camera = { access = 'rear', triggerRadius = 2.40, standOffset = 1.42, camLocalX = 0.007, camLocalY = -3.531, camLocalZ = 0.982, lookLocalX = 0.012, lookLocalY = -1.230, lookLocalZ = 0.005, fov = 52.0 },
   light = { spots = { { pos = { x = 0.000, y = -2.439, z = 0.656 }, look = { x = 0.000, y = -2.013, z = 0.206 }, color = { r = 255, g = 235, b = 190 }, brightness = 7.80, spotFov = 60.00, distance = 0.90, radius = 12.00, falloff = 18.00 } } },
  },
  seminole = {
   camera = { access = 'rear', triggerRadius = 2.90, standOffset = 1.95, camLocalX = 0.019, camLocalY = -3.185, camLocalZ = 1.114, lookLocalX = 0.019, lookLocalY = -0.838, lookLocalZ = 0.254, fov = 52.0 },
  },
  seminole2 = {
   camera = { access = 'rear', triggerRadius = 2.90, standOffset = 1.95, camLocalX = -0.012, camLocalY = -2.703, camLocalZ = 1.022, lookLocalX = 0.004, lookLocalY = -0.403, lookLocalZ = 0.042, fov = 52.0 },
  },
  sentinel = {
   spawn = { y = -1.772, z = 0.119, areaPoints = { { y = -1.417, x = -0.503 }, { y = -1.457, x = -0.017 }, { y = -1.422, x = 0.5 }, { y = -2.078, x = 0.533 }, { y = -2.162, x = 0.363 }, { y = -2.196, x = -0.152 }, { y = -2.163, x = -0.362 }, { y = -2.088, x = -0.527 } }, x = 0.04 },
   camera = { standOffset = 1.5, camLocalZ = 1.062, access = 'rear', fov = 52, camLocalX = 0.036, lookLocalX = 0.083, camLocalY = -3.092, lookLocalY = -0.872, lookLocalZ = -0.087, triggerRadius = 2.5 },
   light = { spots = { { pos = { y = -2.139, z = 0.886, x = 0 }, brightness = 1.05, spotFov = 55, falloff = 18, look = { y = -1.846, z = 0.094, x = 0 }, roundness = 0.2, radius = 55, color = { r = 255, g = 235, b = 190 }, distance = 2.2 } } },
  },
  sentinel2 = {
   spawn = { x = 0.000, y = -1.955, z = 0.121, areaPoints = { { x = -0.407, y = -1.784 }, { x = 0.396, y = -1.795 }, { x = 0.390, y = -2.177 }, { x = -0.387, y = -2.177 } } },
   camera = { access = 'rear', triggerRadius = 2.50, standOffset = 1.50, camLocalX = 0.008, camLocalY = -2.703, camLocalZ = 0.952, lookLocalX = -0.005, lookLocalY = -0.768, lookLocalZ = -0.630, fov = 52.0 },
   light = { spots = { { pos = { x = 0.000, y = -2.103, z = 0.593 }, look = { x = 0.000, y = -1.941, z = 0.079 }, color = { r = 255, g = 235, b = 190 }, brightness = 1.40, spotFov = 44.90, distance = 2.10, radius = 12.00, falloff = 18.00 } } },
  },
  serrano = {
   camera = { access = 'rear', triggerRadius = 2.90, standOffset = 1.95, camLocalX = -0.016, camLocalY = -2.890, camLocalZ = 1.008, lookLocalX = 0.006, lookLocalY = -0.755, lookLocalZ = -0.293, fov = 52.0 },
  },
  speedo = {
   spawn = { x = 0.000, y = -1.317, z = -0.232, areaPoints = { { x = -0.804, y = 0.253 }, { x = 0.874, y = 0.297 }, { x = 0.862, y = -1.095 }, { x = 0.652, y = -1.459 }, { x = 0.652, y = -2.363 }, { x = 0.860, y = -2.379 }, { x = 0.856, y = -2.719 }, { x = -0.836, y = -2.707 }, { x = -0.820, y = -2.371 }, { x = -0.676, y = -2.371 }, { x = -0.668, y = -1.475 }, { x = -0.832, y = -1.083 } } },
   camera = { access = 'rear', triggerRadius = 3.20, standOffset = 2.20, camLocalX = 0.004, camLocalY = -4.381, camLocalZ = 0.781, lookLocalX = 0.011, lookLocalY = -1.971, lookLocalZ = 0.116, fov = 52.0 },
   light = { spots = { { pos = { x = 0.000, y = -2.577, z = 0.864 }, look = { x = 0.000, y = -1.423, z = -0.282 }, color = { r = 255, g = 235, b = 190 }, brightness = 6.00, spotFov = 56.90, distance = 1.70, radius = 12.00, falloff = 18.00 } } },
  },
  squaddie = {
   camera = { access = 'rear', triggerRadius = 2.90, standOffset = 1.95, camLocalX = 0.000, camLocalY = -3.228, camLocalZ = 1.358, lookLocalX = -0.025, lookLocalY = -1.071, lookLocalZ = 0.094, fov = 52.0 },
  },
  stafford = {
   camera = { access = 'rear', triggerRadius = 2.60, standOffset = 1.55, camLocalX = -0.003, camLocalY = -3.266, camLocalZ = 1.103, lookLocalX = -0.006, lookLocalY = -1.279, lookLocalZ = -0.415, fov = 52.0 },
  },
  stanier = {
   camera = { access = 'rear', triggerRadius = 2.60, standOffset = 1.55, camLocalX = -0.000, camLocalY = -3.373, camLocalZ = 0.781, lookLocalX = -0.003, lookLocalY = -1.118, lookLocalZ = -0.299, fov = 52.0 },
  },
  stockade = {
   spawn = { x = 0.000, y = -2.500, z = 0.447, areaPoints = { { x = -0.706, y = -1.006 }, { x = 0.717, y = -0.995 }, { x = 0.730, y = -3.451 }, { x = -0.726, y = -3.454 } } },
   camera = { access = 'rear', triggerRadius = 3.40, standOffset = 2.40, camLocalX = 0.049, camLocalY = -4.734, camLocalZ = 1.868, lookLocalX = 0.105, lookLocalY = -2.443, lookLocalZ = 0.868, fov = 52.0 },
   light = { spots = { { pos = { x = 0.000, y = -2.248, z = 2.191 }, look = { x = 0.000, y = -2.110, z = 0.397 }, color = { r = 255, g = 235, b = 190 }, brightness = 6.00, spotFov = 47.60, distance = 2.20, radius = 12.00, falloff = 18.00 } } },
  },
  stratum = {
   camera = { access = 'rear', triggerRadius = 2.60, standOffset = 1.55, camLocalX = 0.006, camLocalY = -2.900, camLocalZ = 1.088, lookLocalX = -0.017, lookLocalY = -0.845, lookLocalZ = -0.335, fov = 52.0 },
  },
  stretch = {
   camera = { access = 'rear', triggerRadius = 2.60, standOffset = 1.55, camLocalX = 0.000, camLocalY = -4.591, camLocalZ = 0.778, lookLocalX = -0.021, lookLocalY = -2.493, lookLocalZ = -0.581, fov = 52.0 },
  },
  sultan = {
   spawn = { x = 0.000, y = -1.786, z = 0.072, areaPoints = { { x = -0.524, y = -1.624 }, { x = -0.398, y = -1.628 }, { x = -0.394, y = -1.340 }, { x = 0.388, y = -1.312 }, { x = 0.412, y = -1.600 }, { x = 0.524, y = -1.592 }, { x = 0.548, y = -1.968 }, { x = -0.508, y = -1.960 } } },
   camera = { access = 'rear', triggerRadius = 2.40, standOffset = 1.42, camLocalX = -0.020, camLocalY = -2.633, camLocalZ = 0.893, lookLocalX = 0.016, lookLocalY = -0.496, lookLocalZ = -0.404, fov = 52.0 },
   light = { spots = { { pos = { x = 0.000, y = -2.078, z = 0.520 }, look = { x = -0.040, y = -1.660, z = 0.150 }, color = { r = 255, g = 235, b = 190 }, brightness = 17.40, spotFov = 60.00, distance = 2.90, radius = 12.00, falloff = 18.30 } } },
  },
  sultan2 = {
   spawn = { x = 0.000, y = -1.778, z = 0.248, areaPoints = { { x = -0.388, y = -1.656 }, { x = -0.390, y = -1.444 }, { x = 0.030, y = -1.516 }, { x = 0.388, y = -1.456 }, { x = 0.380, y = -1.648 }, { x = 0.652, y = -1.656 }, { x = 0.644, y = -1.952 }, { x = 0.340, y = -2.016 }, { x = -0.020, y = -2.028 }, { x = -0.324, y = -2.018 }, { x = -0.636, y = -1.952 }, { x = -0.656, y = -1.668 } } },
   camera = { access = 'rear', triggerRadius = 2.40, standOffset = 1.42, camLocalX = 0.015, camLocalY = -2.704, camLocalZ = 0.949, lookLocalX = -0.018, lookLocalY = -0.502, lookLocalZ = -0.233, fov = 52.0 },
   light = { spots = { { pos = { x = 0.000, y = -1.574, z = 0.552 }, look = { x = 0.000, y = -1.660, z = 0.246 }, color = { r = 255, g = 235, b = 190 }, brightness = 6.00, spotFov = 60.00, distance = 2.20, radius = 12.00, falloff = 18.00 } } },
  },
  sultan3 = {
   spawn = { x = 0.000, y = -1.801, z = 0.128, areaPoints = { { x = -0.444, y = -1.487 }, { x = 0.466, y = -1.475 }, { x = 0.454, y = -1.643 }, { x = 0.652, y = -1.615 }, { x = 0.636, y = -1.975 }, { x = -0.636, y = -1.975 }, { x = -0.620, y = -1.615 }, { x = -0.452, y = -1.615 } } },
   camera = { access = 'rear', triggerRadius = 2.40, standOffset = 1.42, camLocalX = 0.002, camLocalY = -2.854, camLocalZ = 1.207, lookLocalX = 0.021, lookLocalY = -0.936, lookLocalZ = -0.395, fov = 52.0 },
   light = { spots = { { pos = { x = 0.000, y = -1.957, z = 0.504 }, look = { x = 0.000, y = -1.643, z = 0.134 }, color = { r = 255, g = 235, b = 190 }, brightness = 1.30, spotFov = 59.80, distance = 0.90, radius = 12.00, falloff = 18.00 } } },
  },
  sultanrs = {
   spawn = { x = 0.000, y = -1.724, z = 0.104, areaPoints = { { x = -0.652, y = -1.578 }, { x = -0.462, y = -1.566 }, { x = -0.450, y = -1.286 }, { x = 0.452, y = -1.282 }, { x = 0.444, y = -1.554 }, { x = 0.636, y = -1.558 }, { x = 0.532, y = -2.074 }, { x = -0.020, y = -2.130 }, { x = -0.532, y = -2.082 } } },
   camera = { access = 'rear', triggerRadius = 2.35, standOffset = 1.40, camLocalX = 0.007, camLocalY = -3.044, camLocalZ = 0.786, lookLocalX = -0.007, lookLocalY = -0.755, lookLocalZ = -0.217, fov = 52.0 },
   light = { spots = { { pos = { x = 0.000, y = -2.296, z = 0.504 }, look = { x = 0.000, y = -1.702, z = 0.054 }, color = { r = 255, g = 235, b = 190 }, brightness = 2.30, spotFov = 39.90, distance = 1.60, radius = 12.00, falloff = 18.00 } } },
  },
  superd = {
   camera = { access = 'rear', triggerRadius = 2.60, standOffset = 1.55, camLocalX = -0.000, camLocalY = -3.589, camLocalZ = 0.824, lookLocalX = 0.009, lookLocalY = -1.397, lookLocalZ = -0.377, fov = 52.0 },
  },
  surge = {
   spawn = { x = 0.000, y = -1.510, z = -0.096, areaPoints = { { x = -0.572, y = -1.188 }, { x = 0.594, y = -1.208 }, { x = 0.582, y = -1.720 }, { x = 0.452, y = -1.828 }, { x = 0.012, y = -1.868 }, { x = -0.396, y = -1.852 }, { x = -0.532, y = -1.660 } } },
   camera = { access = 'rear', triggerRadius = 2.60, standOffset = 1.55, camLocalX = 0.002, camLocalY = -2.741, camLocalZ = 0.502, lookLocalX = -0.022, lookLocalY = -0.399, lookLocalZ = -0.373, fov = 52.0 },
   light = { spots = { { pos = { x = 0.000, y = -2.034, z = 0.304 }, look = { x = 0.000, y = -1.472, z = -0.146 }, color = { r = 255, g = 235, b = 190 }, brightness = 2.90, spotFov = 40.10, distance = 2.80, radius = 12.00, falloff = 18.00 } } },
  },
  tailgater2 = {
   camera = { access = 'rear', triggerRadius = 2.60, standOffset = 1.55, camLocalX = -0.004, camLocalY = -2.639, camLocalZ = 0.974, lookLocalX = -0.021, lookLocalY = -0.547, lookLocalZ = -0.396, fov = 52.0 },
  },
  taxi = {
   spawn = { x = 0.000, y = -1.801, z = -0.200, areaPoints = { { x = -0.628, y = -1.295 }, { x = 0.620, y = -1.311 }, { x = 0.612, y = -2.263 }, { x = -0.604, y = -2.271 } } },
   camera = { access = 'rear', triggerRadius = 2.80, standOffset = 1.79, camLocalX = 0.001, camLocalY = -3.291, camLocalZ = 0.627, lookLocalX = 0.000, lookLocalY = -0.897, lookLocalZ = -0.092, fov = 52.0 },
   light = { spots = { { pos = { x = 0.000, y = -2.413, z = 0.568 }, look = { x = 0.032, y = -1.715, z = -0.250 }, color = { r = 255, g = 235, b = 190 }, brightness = 6.00, spotFov = 34.40, distance = 2.20, radius = 12.00, falloff = 18.00 } } },
  },
  tenf = {
   camera = { access = 'front', triggerRadius = 2.50, standOffset = 1.90, rearDistance = 0.24, rearHeight = 1.28, lookHeight = 1.06 },
  },
  tenf2 = {
   camera = { access = 'front', triggerRadius = 2.50, standOffset = 1.90, rearDistance = 0.24, rearHeight = 1.28, lookHeight = 1.06 },
  },
  tornado = {
   spawn = { x = 0.000, y = -2.360, z = -0.192, areaPoints = { { x = -0.540, y = -1.910 }, { x = 0.532, y = -1.902 }, { x = 0.532, y = -2.126 }, { x = 0.684, y = -2.126 }, { x = 0.676, y = -2.662 }, { x = -0.652, y = -2.662 }, { x = -0.660, y = -2.150 }, { x = -0.528, y = -2.150 } } },
   camera = { access = 'rear', triggerRadius = 2.45, standOffset = 1.45, camLocalX = 0.000, camLocalY = -3.399, camLocalZ = 0.949, lookLocalX = -0.019, lookLocalY = -1.395, lookLocalZ = -0.544, fov = 52.0 },
   light = { spots = { { pos = { x = 0.000, y = -2.652, z = 0.728 }, look = { x = 0.000, y = -2.282, z = -0.242 }, color = { r = 255, g = 235, b = 190 }, brightness = 5.40, spotFov = 34.90, distance = 1.90, radius = 12.00, falloff = 18.00 } } },
  },
  warrener = {
   camera = { access = 'rear', triggerRadius = 2.60, standOffset = 1.55, camLocalX = -0.003, camLocalY = -2.880, camLocalZ = 1.238, lookLocalX = 0.008, lookLocalY = -0.818, lookLocalZ = -0.176, fov = 52.0 },
  },
  washington = {
   spawn = { x = 0.000, y = -2.108, z = -0.088, areaPoints = { { x = -0.588, y = -2.066 }, { x = -0.430, y = -2.054 }, { x = -0.386, y = -1.838 }, { x = 0.404, y = -1.850 }, { x = 0.396, y = -2.050 }, { x = 0.564, y = -2.062 }, { x = 0.548, y = -2.482 }, { x = 0.404, y = -2.542 }, { x = -0.388, y = -2.538 }, { x = -0.580, y = -2.482 } } },
   camera = { access = 'rear', triggerRadius = 2.60, standOffset = 1.55, camLocalX = 0.010, camLocalY = -3.626, camLocalZ = 0.906, lookLocalX = -0.002, lookLocalY = -1.351, lookLocalZ = -0.130, fov = 52.0 },
   light = { spots = { { pos = { x = 0.000, y = -2.696, z = 0.384 }, look = { x = 0.000, y = -2.094, z = -0.138 }, color = { r = 255, g = 235, b = 190 }, brightness = 0.60, spotFov = 44.40, distance = 2.80, radius = 12.00, falloff = 18.00 } } },
  },
  weevil = {
   spawn = { x = 0.000, y = -2.295, z = 0.320, areaPoints = { { x = -0.500, y = -1.845 }, { x = -0.150, y = -1.745 }, { x = 0.150, y = -1.745 }, { x = 0.500, y = -1.845 }, { x = 0.580, y = -2.445 }, { x = 0.300, y = -3.045 }, { x = -0.300, y = -3.045 }, { x = -0.580, y = -2.445 } } },
   camera = { access = 'rear', triggerRadius = 2.60, standOffset = 1.67, camLocalX = -0.151, camLocalY = 2.479, camLocalZ = 1.264, lookLocalX = -0.077, lookLocalY = 0.333, lookLocalZ = -0.017, fov = 52.0 },
   light = { spots = { { pos = { x = 0.000, y = -2.195, z = 0.720 }, look = { x = 0.000, y = -2.945, z = 0.270 }, color = { r = 255, g = 235, b = 190 }, brightness = 6.00, spotFov = 12.00, distance = 2.20, radius = 12.00, falloff = 18.00 } } },
  },
  windsor = {
   spawn = { x = 0.000, y = -2.261, z = 0.047, areaPoints = { { x = -0.539, y = -2.025 }, { x = 0.537, y = -2.024 }, { x = 0.537, y = -2.218 }, { x = 0.740, y = -2.213 }, { x = 0.697, y = -2.561 }, { x = 0.477, y = -2.597 }, { x = -0.001, y = -2.630 }, { x = -0.495, y = -2.595 }, { x = -0.700, y = -2.558 }, { x = -0.740, y = -2.210 }, { x = -0.537, y = -2.212 } } },
   camera = { access = 'rear', triggerRadius = 2.50, standOffset = 1.50, camLocalX = 0.003, camLocalY = -3.475, camLocalZ = 0.925, lookLocalX = 0.004, lookLocalY = -1.270, lookLocalZ = -0.253, fov = 52.0 },
   light = { spots = { { pos = { x = 0.000, y = -2.273, z = 0.559 }, look = { x = 0.000, y = -2.215, z = 0.093 }, color = { r = 255, g = 235, b = 190 }, brightness = 6.00, spotFov = 60.00, distance = 2.20, radius = 12.00, falloff = 18.00 } } },
  },
  windsor2 = {
   camera = { access = 'rear', triggerRadius = 2.50, standOffset = 1.50, camLocalX = -0.002, camLocalY = -3.466, camLocalZ = 0.942, lookLocalX = 0.013, lookLocalY = -1.590, lookLocalZ = -0.711, fov = 52.0 },
  },
  xls = {
   camera = { access = 'rear', triggerRadius = 2.90, standOffset = 1.95, camLocalX = 0.073, camLocalY = -3.126, camLocalZ = 0.741, lookLocalX = -0.061, lookLocalY = -0.989, lookLocalZ = -0.549, fov = 52.0 },
  },
  xls2 = {
   spawn = { x = 0.032, y = -2.068, z = -0.152, areaPoints = { { x = -0.377, y = -2.101 }, { x = -0.364, y = -1.453 }, { x = -0.004, y = -1.459 }, { x = 0.382, y = -1.466 }, { x = 0.379, y = -1.750 }, { x = 0.379, y = -2.078 }, { x = 0.720, y = -2.105 }, { x = 0.691, y = -2.380 }, { x = 0.567, y = -2.444 }, { x = 0.318, y = -2.482 }, { x = 0.047, y = -2.498 }, { x = -0.360, y = -2.477 }, { x = -0.584, y = -2.432 }, { x = -0.677, y = -2.379 }, { x = -0.688, y = -2.274 }, { x = -0.718, y = -2.139 } } },
   camera = { access = 'rear', triggerRadius = 2.90, standOffset = 1.95, camLocalX = -0.067, camLocalY = -3.128, camLocalZ = 0.741, lookLocalX = 0.048, lookLocalY = -0.971, lookLocalZ = -0.516, fov = 52.0 },
   light = { spots = { { pos = { x = 0.064, y = -2.728, z = 1.008 }, look = { x = 0.000, y = -1.726, z = 0.062 }, color = { r = 255, g = 255, b = 190 }, brightness = 8.72, spotFov = 40.30, distance = 2.20, radius = 12.00, falloff = 18.00 } } },
  },
  zion = {
   spawn = { x = 0.000, y = -1.910, z = 0.048, areaPoints = { { x = -0.483, y = -1.966 }, { x = -0.498, y = -1.585 }, { x = 0.505, y = -1.597 }, { x = 0.484, y = -2.008 }, { x = 0.673, y = -2.003 }, { x = 0.639, y = -2.126 }, { x = 0.506, y = -2.184 }, { x = 0.489, y = -2.240 }, { x = 0.032, y = -2.303 }, { x = -0.504, y = -2.239 }, { x = -0.557, y = -2.150 }, { x = -0.661, y = -2.115 }, { x = -0.665, y = -1.959 } } },
   camera = { access = 'rear', triggerRadius = 2.50, standOffset = 1.50, camLocalX = 0.040, camLocalY = -2.969, camLocalZ = 0.942, lookLocalX = 0.076, lookLocalY = -0.801, lookLocalZ = -0.302, fov = 52.0 },
   light = { spots = { { pos = { x = 0.016, y = -1.723, z = 0.448 }, look = { x = 0.016, y = -1.656, z = -0.002 }, color = { r = 255, g = 235, b = 190 }, brightness = 2.08, spotFov = 59.80, distance = 2.20, radius = 12.00, falloff = 18.00 } } },
  },
  zion2 = {
   spawn = { x = 0.000, y = -1.926, z = 0.024, areaPoints = { { x = -0.719, y = -1.962 }, { x = -0.498, y = -1.960 }, { x = -0.504, y = -1.761 }, { x = -0.513, y = -1.584 }, { x = -0.134, y = -1.579 }, { x = 0.126, y = -1.577 }, { x = 0.512, y = -1.569 }, { x = 0.495, y = -1.791 }, { x = 0.486, y = -1.954 }, { x = 0.703, y = -1.965 }, { x = 0.655, y = -2.113 }, { x = 0.570, y = -2.148 }, { x = 0.507, y = -2.232 }, { x = 0.134, y = -2.278 }, { x = -0.040, y = -2.289 }, { x = -0.519, y = -2.232 }, { x = -0.571, y = -2.160 }, { x = -0.652, y = -2.136 } } },
   camera = { access = 'rear', triggerRadius = 2.50, standOffset = 1.50, camLocalX = -0.001, camLocalY = -2.841, camLocalZ = 1.012, lookLocalX = -0.031, lookLocalY = -0.800, lookLocalZ = -0.431, fov = 52.0 },
   light = { spots = { { pos = { x = 0.000, y = -2.082, z = 0.600 }, look = { x = 0.008, y = -1.968, z = 0.142 }, color = { r = 255, g = 255, b = 190 }, brightness = 1.06, spotFov = 60.00, distance = 2.20, radius = 12.00, falloff = 18.00 } } },
  },
  [-2115434615] = {   -- modelo nao identificado (hash)
   spawn = { x = 0.000, y = -1.729, z = 0.077, areaPoints = { { x = -0.578, y = -1.195 }, { x = 0.576, y = -1.203 }, { x = 0.576, y = -1.799 }, { x = 0.748, y = -1.793 }, { x = 0.739, y = -1.951 }, { x = 0.654, y = -2.107 }, { x = 0.540, y = -2.186 }, { x = 0.379, y = -2.257 }, { x = 0.182, y = -2.290 }, { x = 0.011, y = -2.301 }, { x = -0.252, y = -2.279 }, { x = -0.377, y = -2.259 }, { x = -0.568, y = -2.174 }, { x = -0.667, y = -2.083 }, { x = -0.748, y = -1.918 }, { x = -0.757, y = -1.800 }, { x = -0.580, y = -1.798 } } },
   camera = { access = 'rear', triggerRadius = 2.50, standOffset = 1.50, camLocalX = 0.016, camLocalY = -2.744, camLocalZ = 0.775, lookLocalX = -0.005, lookLocalY = -0.590, lookLocalZ = -0.494, fov = 52.0 },
   light = { spots = { { pos = { x = 0.000, y = -1.541, z = 0.565 }, look = { x = 0.000, y = -1.547, z = 0.027 }, color = { r = 255, g = 235, b = 190 }, brightness = 6.00, spotFov = 60.00, distance = 2.20, radius = 12.00, falloff = 18.00 } } },
  },
  [-429055721] = {   -- modelo nao identificado (hash)
   spawn = { x = 0.000, y = -2.439, z = -0.096, areaPoints = { { x = -0.546, y = -2.157 }, { x = -0.150, y = -2.161 }, { x = 0.150, y = -2.157 }, { x = 0.548, y = -2.163 }, { x = 0.549, y = -2.726 }, { x = 0.300, y = -2.725 }, { x = -0.300, y = -2.725 }, { x = -0.547, y = -2.709 } } },
   camera = { access = 'rear', triggerRadius = 2.60, standOffset = 1.55, camLocalX = 0.004, camLocalY = -3.755, camLocalZ = 0.600, lookLocalX = -0.009, lookLocalY = -1.388, lookLocalZ = -0.205, fov = 52.0 },
   light = { spots = { { pos = { x = 0.000, y = -2.203, z = 0.376 }, look = { x = 0.000, y = -2.401, z = -0.058 }, color = { r = 255, g = 235, b = 190 }, brightness = 2.88, spotFov = 60.00, distance = 2.20, radius = 12.00, falloff = 18.00 } } },
  },
  [1247528986] = {   -- modelo nao identificado (hash)
   camera = { access = 'rear', triggerRadius = 2.90, standOffset = 1.95, camLocalX = -0.002, camLocalY = -3.289, camLocalZ = 1.023, lookLocalX = 0.041, lookLocalY = -1.246, lookLocalZ = -0.418, fov = 52.0 },
  },
  [1383483872] = {   -- modelo nao identificado (hash)
   camera = { access = 'rear', triggerRadius = 2.60, standOffset = 1.55, camLocalX = 0.022, camLocalY = -2.820, camLocalZ = 0.833, lookLocalX = -0.019, lookLocalY = -0.824, lookLocalZ = -0.672, fov = 52.0 },
  },
 },
 class = {
  [1] = { triggerRadius = 2.6, standOffset = 1.55, rearDistance = 0.45, rearHeight = 0.76, lookHeight = 0.38 },
  [2] = { triggerRadius = 2.9, standOffset = 1.95, rearDistance = 0.62, rearHeight = 0.98, lookHeight = 0.52 },
  [3] = { triggerRadius = 2.5, standOffset = 1.5, rearDistance = 0.44, rearHeight = 0.74, lookHeight = 0.36 },
  [4] = { triggerRadius = 2.5, standOffset = 1.5, rearDistance = 0.46, rearHeight = 0.76, lookHeight = 0.38 },
  [5] = { triggerRadius = 2.45, standOffset = 1.45, rearDistance = 0.42, rearHeight = 0.7, lookHeight = 0.34 },
  [6] = { triggerRadius = 2.4, standOffset = 1.42, rearDistance = 0.38, rearHeight = 0.66, lookHeight = 0.32 },
  [7] = { triggerRadius = 2.35, standOffset = 1.4, rearDistance = 0.34, rearHeight = 0.62, lookHeight = 0.28 },
  [8] = { mode = 'saddlebag', doorless = true, triggerRadius = 2.1, standOffset = 1.2 },
  [9] = { triggerRadius = 2.8, standOffset = 1.7, rearDistance = 0.55, rearHeight = 0.84, lookHeight = 0.44 },
  [10] = { mode = 'pickup', triggerRadius = 3.0, standOffset = 1.95, rearDistance = 0.74, rearHeight = 0.92, lookHeight = 0.5 },
  [11] = { mode = 'utility', triggerRadius = 3.0, standOffset = 1.95, rearDistance = 0.74, rearHeight = 0.92, lookHeight = 0.5 },
  [12] = { mode = 'van', triggerRadius = 3.2, standOffset = 2.2, rearDistance = 0.86, rearHeight = 0.98, lookHeight = 0.56 },
  [20] = { mode = 'commercial', triggerRadius = 3.4, standOffset = 2.4, rearDistance = 0.95, rearHeight = 1.02, lookHeight = 0.6 },
 },
 backEngine = { 'ninef', 'adder', 'vagner', 't20', 'infernus', 'zentorno', 'reaper', 'comet2', 'comet3', 'jester', 'jester2', 'cheetah', 'cheetah2', 'prototipo', 'turismor', 'pfister811', 'osiris', 'entityxf', 'fmj', 'bullet', 'nero', 'nero2', 'tenf', 'tenf2' },
}
