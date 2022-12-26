profile="NACA2412"
if length(ARGS)>0
    profile=ARGS[1]
end
m=parse(Float64,profile[5:5])/100
p=parse(Float64,profile[6:6])/10
t=parse(Float64,profile[7:8])/100
if haskey(ENV,"m")
    m=parse(Float64,ENV["m"])
end

if haskey(ENV,"p")
    p=parse(Float64,ENV["p"])
end

if haskey(ENV,"t")
    t=parse(Float64,ENV["t"])
end

delta_y(x)= 5*t*(0.298222773*sqrt(x) - 0.127125232*x - 0.357907906*x^2 + 0.291984971*x^3 - 0.105174606*x^4)
y_c(x)= x<p ? m/p^2*(2*p*x-x^2) : m/(1-p)^2*((1-2*p)+2*p*x-x^2)

# using Plots
# x=0.0:0.001:1.2
#plot(x,y.(x))
n_points_per_side=200
n_aerofoil_points=2*n_points_per_side
bounding_radius=7.0
far_field_mesh_size=0.3
airfoil_mesh_size=1e-3
run(`./set_config_property.sh name unstructured_gmsh_$(airfoil_mesh_size)_$(far_field_mesh_size)`)
touch("aerofoil.geo")
open("aerofoil.geo","w")do io
    for i in 1:n_points_per_side
        x=(i-1)/(n_points_per_side)
        mesh_size=airfoil_mesh_size#0.05#1*x*(1-x)+0.005
        println(io,"Point($i) = {$x, $(y_c(x)+delta_y(x)), 0.0,$mesh_size};")
    end
    for i in 1:n_points_per_side
        x=1-(i-1)/(n_points_per_side)
        mesh_size=airfoil_mesh_size#0.05#1*x*(1-x)+0.005
        println(io,"Point($(i+n_points_per_side)) = {$(x), $(y_c(x)-delta_y(x)), 0.0,$mesh_size};")
    end
    println(io,"""Spline(1)={1:$n_aerofoil_points,1};""")

    println(io,"Point($(n_aerofoil_points+1)) = {0.0, $(bounding_radius), 0.0, $far_field_mesh_size};")
    println(io,"Point($(n_aerofoil_points+2)) = {0.0, $(-bounding_radius), 0.0, $far_field_mesh_size};")
    println(io,"Point($(n_aerofoil_points+3)) = {$(-bounding_radius), 0.0, 0.0, $far_field_mesh_size};")
    println(io,"Point($(n_aerofoil_points+4)) = {$(bounding_radius), $(bounding_radius), 0.0, $far_field_mesh_size};")
    println(io,"Point($(n_aerofoil_points+5)) = {$(bounding_radius), $(-bounding_radius), 0.0, $far_field_mesh_size};")
    println(io,"Circle($(n_aerofoil_points+1))= {$(n_aerofoil_points+2), 1, $(n_aerofoil_points+3)};")
    println(io,"Circle($(n_aerofoil_points+2))= {$(n_aerofoil_points+3), 1, $(n_aerofoil_points+1)};")
    println(io,"Line($(n_aerofoil_points+3)) = {$(n_aerofoil_points+1), $(n_aerofoil_points+4)};")
    println(io,"Line($(n_aerofoil_points+4)) = {$(n_aerofoil_points+4), $(n_aerofoil_points+5)};")
    println(io,"Line($(n_aerofoil_points+5)) = {$(n_aerofoil_points+5), $(n_aerofoil_points+2)};")


    println(io,"Curve Loop(2) = {$(join((n_aerofoil_points+1):(n_aerofoil_points+5),","))};")
    println(io,"Curve Loop(3) = {1};")
    println(io,"Plane Surface(1) = {2,3};")
    # #println(io,"Physical Curve(\"WALL\") = {2};")
    #println(io,"Plane Surface(1) = {1,2};")
    println(io,"""
    meshThickness=1.0;
    surfaceVector[] = Extrude {0, 0, meshThickness} {
        Surface{1};
        Layers{1};
        Recombine;
    };

    Physical Volume("internalField") = surfaceVector[1];
    Physical Surface("frontAndBackPlanes") = {surfaceVector[0],1};
    Physical Surface("INLET")={surfaceVector[2],surfaceVector[3]};
    Physical Surface("OUTLET")={surfaceVector[5]};
    Physical Surface("AIRFOIL")={surfaceVector[7]};
    Physical Surface("WALL")={surfaceVector[4],surfaceVector[6]};
    Recombine Surface{1};
    Recombine Surface{1};
    Field[1] = Box;
    Field[1].XMax = 3;
    Field[1].XMin = -0.3;
    Field[1].YMax = 1.5;
    Field[1].YMin = -0.3;
    Field[1].Thickness = 0.1;
    Field[1].VIn = 0.02;
    Field[1].ZMax = 2;
    Field[1].ZMin = -1;
    Background Field = 1;
    """)
end
