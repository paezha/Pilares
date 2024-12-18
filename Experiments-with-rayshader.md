---
title: "Experiments with rayrender"
---

# Pilares

After playing around with the system [corpuscular](https://github.com/paezha/corpuscular) I began to think of sculpture spaces. 

Recently I had the good fortune of visiting [Giardino delle Sculture](https://ar.ch.it/exhibitions/giardino-delle-sculture-a-museum-conceived-through-open-air-rooms-for-the-part-museum-of-rimini) in Rimini. This is a small sculpture garden with some truly amazing pieces. This garden feels cozy and intimate: the largest pieces must be around 2.5 or three meters tall, and the articulation is inviting and meditative.

Compare to [Espacio Escultórico](https://www.atlasobscura.com/places/espacio-escultorico) in Mexico City, with its awe-inspiring monumental scale.

These two similar, yet very different spaces for art got me thinking about how much of art is a matter of scale and perspective. With the "corpuscular" system I wanted to create fantastical vistas. With this variant, which I call "pilares" (pillars/columns) I wish to capture a little bit the sensation of a seeing a sculpture garden from different vantage points. 

Package [{rayrender}](https://www.rayrender.net/index.html) makes it surprisingly easy to do this. Most of the work goes into finding parameters that create pleasing perpsectives. At the moment, I experiment with two colonnades, but it would be interesting to create "gardens" of pillars with other arrangments, such as spirals, etc.

## Preliminaries

This system uses only four packages, {dplyr} for ease of data manipulation, {glue} (mainly for naming files for saving), two packages with color palettes (Blake Mills' wonderful [{MetBrewer}](https://github.com/BlakeRMills/MetBrewer) and my own [{MexBrewer}](https://paezha.github.io/MexBrewer/)), and of course {rayrender}:

```r
library(dplyr)
library(glue)
library(MetBrewer)
library(MexBrewer)
library(rayrender)
```

## Create the columns and the scene

First I sample a number to use as a random seed:

```r
#seed <- 2687084
seed <- sample.int(10000000, 1)
```

Next, I randomly choose a color palette from either {MetBrewer} or {MexBrewer}:

```r
# Select collection of color palettes
edition <- sample(c("MexBrewer", "MetBrewer"), 1)

if(edition=="MexBrewer"){
  # Randomly select a color palette (MexBrewer Edition)
  palette_name <- sample(c("Alacena", "Atentado", "Aurora", "Concha", "Frida", "Revolucion", "Ronda", "Tierra"), 1)
  # col_palette <- mex.brewer(palette_name, n = 25)
  col_palette <- mex.brewer(palette_name, n = 15)
  
}else{
  # Randomly select a color palette (MetBrewer Edition)
  palette_name <- sample(c("Archaumbault", "Austria", "Benedictus", "Cassatt1", "Cassatt2", "Cross", "Degas", "Demuth", "Derain", "Egypt", "Gauguin", "Greek", "Hiroshige", "Hokusai1", "Hokusai2", "Hokusai3", "Homer1", "Homer2", "Ingres", "Isfahan1", "Isfahan2", "Java", "Johnson", "Juarez", "Kandinsky", "Klimt", "Lakota", "Manet", "Monet", "Moreau", "Morgenstern", "Nattier", "Navajo", "NewKingdom", "Nizami", "OKeeffe1", "OKeeffe2", "Paquin", "Peru1", "Peru2", "Pillement", "Pissaro", "Redon", "Renoir", "Signac", "Tam", "Tara", "Thomas", "Tiepolo", "Troy", "Tsimshian", "VanGogh1", "VanGogh2", 'VanGogh3', "Veronese", "Wissing"), 1)
  col_palette <- met.brewer(palette_name, n = 15)
}
```

Next, I create a data frame with the parameters for the position, radius, and height of the columns. The position in x is on the plane (left-right), y is the vertical axis, and z is on the plane (front-back). The radius must be positive. Given the spacing between columns, the radius should not exceed perhaps 1/8 or so of the spacing. The parameters for expanding the grid create two parallel colonnades 6 units of distance apart. There is plenty of room to play here with the position of the columns! For instance, two colonnades that converge, a single colonnade in a spiral, columns that vary in height as a function of position, etc. In this data frame, the chosen color palette is also used to assign colors at random, but the colors could be a function of position:

```r
df <- expand.grid(x = c(-3, 3), # This is to create two parallel rows of columns; consider adding more
                  z = seq(20, -50, -2.5)) |> # This is the spacing between columns in the z axis (front-back)
  mutate(y = 0, # The columns are on the ground, not floating, not sunk
         l = runif(1, min= 100, max = 300), # The columns are _tall_, between 100 and 300 units tall
         r = 0.15, # The radius is a fraction of the smallest spacing of the columns (which is at the moment 2 in x)
         color = sample(col_palette, 
                        n(), 
                        replace = TRUE))
```

As an alternative, place the pillars following a hyperbolic function:

```r
df <- data.frame(z = seq(20, -50, -2.5)) |> 
  mutate(x =  3 + sample(c(0, -7), 1) + runif(1, min = 0.0002, max = 0.01) * z^2)

df <- rbind(df,
            df |>
              mutate(x = -x)) |> 
  mutate(y = 0, # The columns are on the ground, not floating, not sunk
         l = runif(1, min= 100, max = 300), # The columns are _tall_, between 100 and 300 units tall
         r = runif(1, min = 0.15, max = 0.5), # The radius is a fraction of the smallest spacing of the columns (which is at the moment 2 in x)
         color = sample(col_palette, 
                        n(), 
                        replace = TRUE))
```

Here I initialize an empty data frame and then use `rayrender::cylinder()` for my columns. I have yet to experiment with different materials (`diffuse()`, `glossy()`, etc.). Populate the parameters to create the sphere:

```r
obj <- data.frame()

for(i in 1:nrow(df)){
  obj <- rbind(obj,
               cylinder(x = df$x[i],
                        y = df$y[i],
                        z = df$z[i],
                        radius = df$r[i],
                        l = df$l[i],
                        material = diffuse(color=df$color[i])))
}
```

In this chunk of code, the scene for the rayrendering is initialized with a white ground (the colors for the background will later be set drawing from the chosen color palette):

```r
set.seed(seed)

bkg_c <- sample.int(12, 1) + 3
scene <- generate_ground(material = diffuse(color = col_palette[bkg_c]))
```

After initializing the scene, it is now possible to add the objects (i.e., the columns). Also, I like to include a source of light with random position and intensity:

```r
#set.seed(seed)

scene <- scene |> 
  add_object(objects = obj) |>
  #light source
  add_object(sphere(x = sample(c(-30, 30), 1),
                    y = 20,
                    z = -60,
                    r = 4,
                    material=light(intensity = rlnorm(1, meanlog = 4),
                                   invisible = TRUE)))
```

## Render the scene

Render the scene using randomly drawn colors from the chosen palette for the background. 

```r
#set.seed(seed)

# Select the perspective randomly; this is where a lot of the work happens, finding parameters that produce pleasing perpsectives
x_from <- runif(1, min = -3, max = 3)
z_from <- runif(1, min = 25, max = 35)#sqrt(30^2 - x_from^2))
y_from <- runif(1, min = 0, max = 80) #runif(1, min = 0, max = sqrt(30^2 - x_from^2 - y_from^2))

render_scene(file = glue::glue("pilares-{seed}.png"),
             scene, 
             parallel = TRUE,
             ambient_light = TRUE,
             # Square
             width = 1500, 
             height = 1500,
             # Mastodon Header
             #width = 1500, 
             #height = 500,#1500,
             # iPhone 11
             #width = 828, 
             #height = 1792, 
             # windows wallpaper
             #width = 2560, 
             #height = 1440, 
             samples = 500,#150 + abs(rnorm(1, 0, 100)), 
             backgroundhigh = col_palette[bkg_c],
             backgroundlow = col_palette[bkg_c - sample.int(4, 1)],
             lookfrom = c(x_from, z_from, y_from),
             lookat = c(0, runif(1, min = 1, max = 25), 2))
```

```
## --------------------------Interactive Mode Controls---------------------------
## W/A/S/D: Horizontal Movement: | Q/Z: Vertical Movement | Up/Down: Adjust FOV | ESC: Close
## Left/Right: Adjust Aperture  | 1/2: Adjust Focal Distance | 3/4: Rotate Environment Light 
## P: Print Camera Info | R: Reset Camera |  TAB: Toggle Orbit Mode |  E/C: Adjust Step Size
## K: Save Keyframe | L: Reset Camera to Last Keyframe (if set) | F: Toggle Fast Travel Mode
## Left Mouse Click: Change Look At (new focal distance) | Right Mouse Click: Change Look At
```
