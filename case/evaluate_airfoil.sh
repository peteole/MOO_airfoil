#!/bin/bash

json=$1
p=$(echo $json | jq -r '.p')
m=$(echo $json | jq -r '.m')
t=$(echo $json | jq -r '.t')

source /opt/OpenFOAM/OpenFOAM-10/etc/bashrc
p=$p m=$m t=$t julia mesh_generation.jl
gmsh -3 aerofoil.geo -format msh2
gmshToFoam aerofoil.msh
function setBoundaryType {
    foamDictionary constant/polyMesh/boundary -entry entry0/$1/type -set $2
    #foamDictionary constant/polyMesh/boundary -entry entry0/$1/physicalType -set $3
}
setBoundaryType frontAndBackPlanes empty
setBoundaryType AIRFOIL wall