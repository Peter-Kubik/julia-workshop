FROM jupyter/minimal-notebook

USER root

# Julia dependencies
# install Julia packages in /opt/julia instead of $HOME
ENV JULIA_DEPOT_PATH=/opt/julia
ENV JULIA_PKGDIR=/opt/julia
ENV JULIA_VERSION=1.2.0

RUN mkdir /opt/julia-${JULIA_VERSION} && \
    cd /tmp && \
    wget -q https://julialang-s3.julialang.org/bin/linux/x64/`echo ${JULIA_VERSION} | cut -d. -f 1,2`/julia-${JULIA_VERSION}-linux-x86_64.tar.gz && \
    echo "926ced5dec5d726ed0d2919e849ff084a320882fb67ab048385849f9483afc47 *julia-${JULIA_VERSION}-linux-x86_64.tar.gz" | sha256sum -c - && \
    tar xzf julia-${JULIA_VERSION}-linux-x86_64.tar.gz -C /opt/julia-${JULIA_VERSION} --strip-components=1 && \
    rm /tmp/julia-${JULIA_VERSION}-linux-x86_64.tar.gz

RUN ln -fs /opt/julia-*/bin/julia /usr/local/bin/julia

RUN mkdir /etc/julia && \
    echo "push!(Libdl.DL_LOAD_PATH, \"$CONDA_DIR/lib\")" >> /etc/julia/juliarc.jl && \
    
    # Create JULIA_PKGDIR \
    mkdir $JULIA_PKGDIR && \
    chown $NB_USER $JULIA_PKGDIR && \
    fix-permissions $JULIA_PKGDIR

USER $NB_UID

RUN julia -e 'import Pkg; Pkg.update()'
RUN (test $TEST_ONLY_BUILD || julia -e 'import Pkg; Pkg.add("HDF5")')
RUN    julia -e "using Pkg; pkg\"add IJulia\"; pkg\"precompile\""
RUN    julia -e 'using Pkg; Pkg.REPLMode.pkgstr("add IJulia     ;precompile");using IJulia' 
RUN    julia -e 'using Pkg; Pkg.add(Pkg.PackageSpec(;name="Turing", version="0.6.23"))' 
RUN    julia -e 'using Pkg; Pkg.add(Pkg.PackageSpec(;name="Plots", version="0.25.3"))' 
RUN    julia -e 'using Pkg; Pkg.add(Pkg.PackageSpec(;name="Distributions", version="0.22.3"))'
RUN    julia -e 'using Pkg; Pkg.add(Pkg.PackageSpec(;name="StatsBase", version="0.32.0"))' 
    # move kernelspec out of home \
RUN    mv $HOME/.local/share/jupyter/kernels/julia* $CONDA_DIR/share/jupyter/kernels/ && \
    chmod -R go+rx $CONDA_DIR/share/jupyter && \
    rm -rf $HOME/.local && \
    fix-permissions $JULIA_PKGDIR $CONDA_DIR/share/jupyter
