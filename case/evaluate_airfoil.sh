#!/bin/bash

HOMEDIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

json=$1
p=$(echo $json | jq -r '.p')
m=$(echo $json | jq -r '.m')
t=$(echo $json | jq -r '.t')
angle=$(echo $json | jq -r '.a')
mkdir -p /tmp/airfoil/"$p"_"$m"_"$t"_"$angle"
cp -r ./* /tmp/airfoil/"$p"_"$m"_"$t"_"$angle"
cd /tmp/airfoil/"$p"_"$m"_"$t"_"$angle"
pwd

source /opt/OpenFOAM/OpenFOAM-10/etc/bashrc
p=$p m=$m t=$t julia mesh_generation.jl
gmsh -3 aerofoil.geo -format msh2 -nopopup
gmshToFoam aerofoil.msh
function setBoundaryType {
    foamDictionary constant/polyMesh/boundary -entry entry0/$1/type -set $2
    #foamDictionary constant/polyMesh/boundary -entry entry0/$1/physicalType -set $3
}
setBoundaryType frontAndBackPlanes empty
setBoundaryType AIRFOIL wall
SILENT=1 ./run_at_angle.sh $angle

radangle=$(jq -n $angle\*3.14159265359/180)
C_D=$(tail -n 1 postProcessing/calcForceCoefficients/0/forceCoeffs.dat  | awk '{print "\t" $3}')
C_L=$(tail -n 1 postProcessing/calcForceCoefficients/0/forceCoeffs.dat  | awk '{print "\t" $4}')
tail -n 1 postProcessing/calcForceCoefficients/0/forceCoeffs.dat \
    | awk -v a=$radangle '{print "{\"C_L\": "cos(a)*$4-sin(a)*$3", \"C_D\": "cos(a)*$3+sin(a)", \"C_N\": "$4", \"C_T\": "$3", \"angle\": "a"}"}'\
    > $HOMEDIR/results/"$p"_"$m"_"$t"_"$angle".json

cd $HOMEDIR
cat results/"$p"_"$m"_"$t"_"$angle".json