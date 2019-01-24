#!/bin/bash

### install
# virtualenv hpc
# source hpc/bin/activate
# pip install tensorflow-gpu==1.8.0
# git clone -b cnn_tf_v1.8_compatible --single-branch https://github.com/tensorflow/benchmarks
# cd benchmarks/scripts/tf_cnn_benchmarks
# ./run_all.sh  ## run this script


exec 2<&-
file="hpc.txt"
rm ${file}
cmd="python tf_cnn_benchmarks.py --num_gpus=1 --variable_update=parameter_server"
pipe='| tail -n 2 | head -n 1 | cut -d" " -f 3 >> ${file}'
models=(resnet50 alexnet vgg16 inception3)

# training
echo "### training mode ###" >> ${file} & cat ${file} | tail -n 1
for M in ${models[@]}; do
	echo ${M} >> ${file} & cat ${file} | tail -n 1
	for (( i=0; i < 7; i++ )); do
		bs=$((2**${i}))
		printf "${bs} " >> ${file}
		eval "${cmd} --batch_size=${bs} --model=${M} ${pipe}"
		cat ${file} | tail -n 1
	done
done

# inference
echo "### inference mode ###" >> ${file} & cat ${file} | tail -n 1
for M in ${models[@]}; do
	echo ${M} >> ${file} & cat ${file} | tail -n 1
	for (( i=0; i < 7; i++ )); do
		bs=$((2**${i}))
		printf "${bs} " >> ${file}
		eval "${cmd} --batch_size=${bs} --model=${M} --forward_only=True ${pipe}"
		cat ${file} | tail -n 1
	done
done


# training
# python tf_cnn_benchmarks.py --num_gpus=1 --batch_size=32 --model=resnet50 --variable_update=parameter_server

# inference
# python tf_cnn_benchmarks.py --num_gpus=1 --batch_size=32 --model=resnet50 --variable_update=parameter_server --forward_only=True