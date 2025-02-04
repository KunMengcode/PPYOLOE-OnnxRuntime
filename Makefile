cc        := g++
name      := pro
workdir   := workspace
srcdir    := src
objdir    := objs
stdcpp    := c++11
cuda_home := 
syslib    := 
cpp_pkg   := /usr/local/opencv
cuda_arch := 
nvcc      := $(cuda_home)/bin/nvcc -ccbin=$(cc)

cpp_srcs := $(shell find $(srcdir) -name "*.cpp")
cpp_objs := $(cpp_srcs:.cpp=.cpp.o)
cpp_objs := $(cpp_objs:$(srcdir)/%=$(objdir)/%)
cpp_mk   := $(cpp_objs:.cpp.o=.cpp.mk)


cu_srcs := $(shell find $(srcdir) -name "*.cu")
cu_objs := $(cu_srcs:.cu=.cu.o)
cu_objs := $(cu_objs:$(srcdir)/%=$(objdir)/%)
cu_mk   := $(cu_objs:.cu.o=.cu.mk)

current_dir := $(shell pwd)


link_cuda      := 
link_onnx      := onnxruntime
link_tensorRT  := 
link_opencv    := opencv_core opencv_imgproc opencv_imgcodecs
link_sys       := stdc++ dl
link_librarys  := $(link_cuda) $(link_tensorRT) $(link_sys) $(link_opencv) $(link_onnx)


include_paths := src              \
	$(cpp_pkg)/opencv3.4.4/include  \
	$(cuda_home)/include/protobuf \
	onnxruntime-linux-x64-1.10.0/include  


library_paths := $(syslib) $(cpp_pkg)/opencv3.4.4/lib $(current_dir)/onnxruntime-linux-x64-1.10.0/lib  

empty := 
library_path_export := $(subst $(empty) $(empty),:,$(library_paths))


run_paths     := $(foreach item,$(library_paths),-Wl,-rpath=$(item))
include_paths := $(foreach item,$(include_paths),-I$(item))
library_paths := $(foreach item,$(library_paths),-L$(item))
link_librarys := $(foreach item,$(link_librarys),-l$(item))


cpp_compile_flags := -std=$(stdcpp) -w -g -O0 -m64 -fPIC -fopenmp -pthread
cu_compile_flags  := -std=$(stdcpp) -w -g -O0 -m64 $(cuda_arch) -Xcompiler "$(cpp_compile_flags)"
link_flags        := -pthread -fopenmp -Wl,-rpath='$$ORIGIN'

cpp_compile_flags += $(include_paths)
cu_compile_flags  += $(include_paths)
link_flags        += $(library_paths) $(link_librarys) $(run_paths)


ifneq ($(MAKECMDGOALS), clean)
-include $(cpp_mk) $(cu_mk)
endif

$(name)   : $(workdir)/$(name)

all       : $(name)
run       : $(name)
	@cd $(workdir) && ./$(name) $(run_args)

$(workdir)/$(name) : $(cpp_objs) $(cu_objs)
	@echo Link $@
	@mkdir -p $(dir $@)
	@$(cc) $^ -o $@ $(link_flags)

$(objdir)/%.cpp.o : $(srcdir)/%.cpp
	@echo Compile CXX $<
	@mkdir -p $(dir $@)
	@$(cc) -c $< -o $@ $(cpp_compile_flags)

$(objdir)/%.cu.o : $(srcdir)/%.cu
	@echo Compile CUDA $<
	@mkdir -p $(dir $@)
	@$(nvcc) -c $< -o $@ $(cu_compile_flags)


$(objdir)/%.cpp.mk : $(srcdir)/%.cpp
	@echo Compile depends C++ $<
	@mkdir -p $(dir $@)
	@$(cc) -M $< -MF $@ -MT $(@:.cpp.mk=.cpp.o) $(cpp_compile_flags)
    

$(objdir)/%.cu.mk : $(srcdir)/%.cu
	@echo Compile depends CUDA $<
	@mkdir -p $(dir $@)
	@$(nvcc) -M $< -MF $@ -MT $(@:.cu.mk=.cu.o) $(cu_compile_flags)


clean :
	@rm -rf $(objdir) $(workdir)/$(name) $(workdir)/*.trtmodel $(workdir)/yolov5s.onnx 
	@rm -rf $(workdir)/image-draw.jpg $(workdir)/input-image.jpg $(workdir)/car-pytorch.jpg

.PHONY : clean run $(name)

export LD_LIBRARY_PATH:=$(library_path_export)
