using Gmsh

Gmsh.initialize()
gmsh.model.add("aerofoil")
gmsh.model.geo.add_point(1,2,3)
gmsh.write("aerofoilv2.msh")