module Milestone1

include("Algorithms.jl")
include("Cosmology.jl")
include("Constants.jl")

using .Cosmology
using .Algorithms
using .Constants
using Plots
using LaTeXStrings
using DelimitedFiles
using Distributions
using Printf
Plots.__init__() # workaround with sysimage: https://github.com/JuliaLang/PackageCompiler.jl/issues/786
try
    pgfplotsx()
catch
    println("WARNING: Since you don't have LaTeX with the PGFPlots package installed,")
    println("         the program falls back to using the GR plotting backend.")
    println("         Therefore, the plots may not look fully as intended!")
    ENV["GKSwstype"] = "100" # headless mode (https://discourse.julialang.org/t/plotting-from-a-server/74345/4)
    gr()
end
default(
    minorticks = 10,
    labelfontsize = 12, # default: 11
    legendfontsize = 11, # default: 8
    annotationfontsize = 11, # default: 14
    tickfontsize = 10, # default: 8
    #titlefontsize = 14, # default: 14
    legend_font_halign = :left,
    fontfamily = "Computer Modern",
)

# a hack to "rasterize" a scatter plot
# TODO: plotting scatter points as rects lowers file size?
function scatterheatmaps!(xss, yss, colors, labels, xlims, ylims; nbins=50, kwargs...)
    xgrid = range(xlims...; length=nbins+1)
    ygrid = range(ylims...; length=nbins+1)
    dx = xgrid[2] - xgrid[1]
    dy = ygrid[2] - ygrid[1]
    zgrid = zeros(Int, nbins, nbins)
    for (i, xs, ys) in zip(1:length(xss), xss, yss)
        for (x, y) in zip(xs, ys)
            ix = min(floor(Int, (x - xgrid[1]) / dx) + 1, nbins)
            iy = min(floor(Int, (y - ygrid[1]) / dy) + 1, nbins)
            zgrid[iy,ix] = i
        end
    end
    xgrid = (xgrid[1:end-1] .+ xgrid[2:end]) ./ 2
    ygrid = (ygrid[1:end-1] .+ ygrid[2:end]) ./ 2
    #zgrid = zgrid .!= 0
    colorgrad = cgrad([:white, colors...], alpha=1.0, categorical=false)
    #histogram2d!(xs, ys; bins=(range(xlims...; length=nbins), range(ylims...; length=nbins)), color = colorgrad, colorbar = :none, kwargs...)
    heatmap!(xgrid, ygrid, zgrid; alpha = 1.0, color = colorgrad, colorbar = :none, kwargs...)
    for (color, label) in zip(colors, labels)
        scatter!([xgrid[1]-1], [ygrid[1]-1]; color = color, markerstrokewidth=0, shape = :rect, label = label) # dummy plot with label
    end
    # TODO: hack a label into the legend with a ghost scatter plot?
end

co = ??CDM()
x = range(-15, 5, length=400)
xrm = equality_rm(co)
xm?? = equality_m??(co)
xacc = acceleration_onset(co)
x1, x2, x3, x4 = minimum(x), xrm, xm??, maximum(x)
x0 = 0.0

@printf("??r = ??m:     x = %+4.2f, a = %6.4f, z = %7.2f, ?? = %4.1f Gyr, t = %8.5f Gyr\n", xrm,  a(xrm),  z(xrm),  ??(co, xrm)  / Gyr, t(co, xrm)  / Gyr)
@printf("d??a/dt?? = 0: x = %+4.2f, a = %6.4f, z = %7.2f, ?? = %4.1f Gyr, t = %8.5f Gyr\n", xacc, a(xacc), z(xacc), ??(co, xacc) / Gyr, t(co, xacc) / Gyr)
@printf("??m = ????:     x = %+4.2f, a = %6.4f, z = %7.2f, ?? = %4.1f Gyr, t = %8.5f Gyr\n", xm??,  a(xm??),  z(xm??),  ??(co, xm??)  / Gyr, t(co, xm??)  / Gyr)
@printf("Today:       x = %+4.2f, a = %6.4f, z = %7.2f, ?? = %4.1f Gyr, t = %8.5f Gyr\n", x0,   a(x0),   z(x0),   ??(co, x0)   / Gyr, t(co, x0)   / Gyr)


if !isdir("plots")
    mkdir("plots")
end

# Conformal Hubble parameter
if true || !isfile("plots/conformal_Hubble.pdf")
    println("Plotting plots/conformal_Hubble.pdf")
    plot(xlabel = L"x = \log a", ylabel = L"\log_{10} \Big[ \mathcal{H} \,/\, (100\,\mathrm{km/s/Mpc}) \Big]", legend_position = :topleft, ylims = (-1, +7), yticks = -1:1:+7)
    plot!(x, @. log10(co.H0     / (100*km/Mpc) * ???(co.??r0) * a(x)^(-1  )); linestyle = :dash,  label = "radiation-dominated")
    plot!(x, @. log10(co.H0     / (100*km/Mpc) * ???(co.??m0) * a(x)^(-1/2)); linestyle = :dash,  label = "matter-dominated")
    plot!(x, @. log10(co.H0     / (100*km/Mpc) * ???(co.????0) * a(x)^(+1  )); linestyle = :dash,  label = "cosmological constant-dominated")
    plot!(x, @. log10(aH(co, x) / (100*km/Mpc)                          ); linestyle = :solid, label = "general case", color = :black)
    vline!([xrm, xm??], z_order = :back, color = :gray, linestyle = :dash, label = nothing)
    vline!([xacc], z_order = :back, color = :gray, linestyle = :dot, label = nothing)
    annotate!([-2.5], [6.5], [(L"x_\textrm{acc} = %$(round(xacc, digits=2))", :gray)])
    savefig("plots/conformal_Hubble.pdf")
end

# conformal Hubble parameter 1st derivative
if true || !isfile("plots/conformal_Hubble_derivative1.pdf")
    println("Plotting plots/conformal_Hubble_derivative1.pdf")
    plot(xlabel = L"x = \log a", ylabel = L"\frac{1}{\mathcal{H}} \frac{\mathrm{d}\mathcal{H}}{\mathrm{d} x}", legend_position = :topleft)
    plot!(x, x -> -1;                   linestyle = :dash,  label = "radiation-dominated")
    plot!(x, x -> -1/2;                 linestyle = :dash,  label = "matter-dominated")
    plot!(x, x -> +1;                   linestyle = :dash,  label = "cosmological constant-dominated")
    plot!(x, @. daH(co, x) / aH(co, x); linestyle = :solid, label = "general case", color = :black)
    vline!([xrm, xm??], z_order = :back, color = :gray, linestyle = :dash, label = nothing)
    vline!([xacc], z_order = :back, color = :gray, linestyle = :dot, label = nothing)
    savefig("plots/conformal_Hubble_derivative1.pdf")
end

# Conformal Hubble parameter 2nd derivative
if true || !isfile("plots/conformal_Hubble_derivative2.pdf")
    println("Plotting plots/conformal_Hubble_derivative2.pdf")
    plot(xlabel = L"x = \log a", ylabel = L"\frac{1}{\mathcal{H}} \frac{\mathrm{d}^2\mathcal{H}}{\mathrm{d} x^2}", legend_positions = :topleft, yticks = 0:0.25:1.5, ylims = (0, 1.5))
    plot!(x, x -> ( 1)^2;                linestyle = :dash,  label = "radiation-dominated")
    plot!(x, x -> (-1/2)^2;              linestyle = :dash,  label = "matter-dominated")
    plot!(x, x -> (-1)^2;                linestyle = :dash,  label = "cosmological constant-dominated", color = 1) # same color as radiation
    plot!(x, @. d2aH(co, x) / aH(co, x); linestyle = :solid, label = "general case", color = :black)
    vline!([xrm, xm??], z_order = :back, color = :gray, linestyle = :dash, label = nothing)
    vline!([xacc], z_order = :back, color = :gray, linestyle = :dot, label = nothing)
    savefig("plots/conformal_Hubble_derivative2.pdf")
end

# Product of conformal time and conformal Hubble parameter
if true || !isfile("plots/eta_H.pdf")
    println("Plotting plots/eta_H.pdf")
    plot(xlabel = L"x = \log a", ylabel = L"\log_{10} \Big[ \eta \mathcal{H} \Big]", legend_position = :topleft)

    #plot!(x, x -> log10(1);                      linestyle = :dash,  label = "radiation-dominated")
    plot!(x, @. log10(??(co, x) * aH(co, x)); linestyle = :solid, color = :black, label = "general case")

    aeq_anal = co.??r0 / co.??m0
    ??_anal = @. 2 / (co.H0 * ???(co.??m0)) * (???(a(x) + aeq_anal) - ???(aeq_anal))
    aH_anal = @. a(x) * co.H0 * ???(co.??r0/a(x)^4 + co.??m0/a(x)^3)
    ??_aH_anal = @. ??_anal * aH_anal
    plot!(x, log10.(??_aH_anal); linestyle = :dash, color = 1, label = "radiation-matter universe")

    vline!([xrm, xm??], z_order = :back, color = :gray, linestyle = :dash, label = nothing)

    savefig("plots/eta_H.pdf")
end

# Cosmic and conformal time
if true || !isfile("plots/times.pdf")
    println("Plotting plots/times.pdf")
    plot(xlabel = L"x = \log a", ylabel = L"\log_{10} \Big[ \{t, \eta\} / \mathrm{Gyr} \Big]", legend_position = :bottomright)

    # in a radiation-matter-only universe
    aeq_anal = co.??r0 / co.??m0
    ??_anal = @. 2 / (    co.H0 * ???(co.??m0)) * (???(a(x) + aeq_anal) - ???(aeq_anal))
    t_anal = @. 2 / (3 * co.H0 * ???(co.??m0)) * (???(a(x) + aeq_anal) * (a(x) - 2*aeq_anal) + 2*aeq_anal^(3/2))

    plot!(x, log10.(??.(co, x) / Gyr); linestyle = :solid, color = 0, label = L"\eta \,\, \textrm{(general)}")
    plot!(x, log10.(??_anal    / Gyr); linestyle = :dash,  color = 0, label = L"\eta \,\, \textrm{(radiation-matter universe)}")

    plot!(x, log10.(t.(co, x) / Gyr); linestyle = :solid, color = 1, label = L"t \,\, \textrm{(general)}")
    plot!(x, log10.(t_anal    / Gyr); linestyle = :dash,  color = 1, label = L"t \,\, \textrm{(radiation-matter universe)}")

    vline!([xrm, xm??], z_order = :back, color = :gray, linestyle = :dash, label = nothing)

    savefig("plots/times.pdf")
end

# Density parameters
if true || !isfile("plots/density_parameters.pdf")
    println("Plotting plots/density_parameters.pdf")
    plot(xlabel = L"x = \log a", ylabel = L"\Omega_i", legend_position = (0.05, 0.6), ylims=(-0.05, +1.3))
    plot!(x, ??r.(co, x); label = L"\Omega_r")
    plot!(x, ??m.(co, x); label = L"\Omega_m")
    plot!(x, ??k.(co, x); label = L"\Omega_k = %$(round(Int, ??k(co, 0.0)))")
    plot!(x, ????.(co, x); label = L"\Omega_\Lambda")
    plot!(x, ??.(co, x);  label = L"\sum_s \Omega_s = %$(round(Int, ??(co, 0.0)))")
    plot!([xrm, xrm], [-0.05, 1.2]; z_order = :back, color = :gray, linestyle = :dash, label = nothing)
    plot!([xm??, xm??], [-0.05, 1.2]; z_order = :back, color = :gray, linestyle = :dash, label = nothing)
    annotate!([xrm], [1.25], [(L"x_\textrm{eq}^{rm} = %$(round(xrm; digits=2))", :gray)])
    annotate!([xm??], [1.25], [(L"x_\textrm{eq}^{m\Lambda} = %$(round(xm??; digits=2))", :gray)])
    annotate!([(x1+x2)/2, (x1+x2)/2], [1.14, 1.07], ["radiation", "domination"])
    annotate!([(x2+x3)/2, (x2+x3)/2], [1.14, 1.07], ["matter", "domination"])
    annotate!([(x3+x4)/2, (x3+x4)/2], [1.14, 1.07], ["??", "domination"])
    savefig("plots/density_parameters.pdf")
end

# Supernova MCMC fits and distances
# Inspiration: "A theoretician's analysis of the supernova data ..." (https://arxiv.org/abs/astro-ph/0212573)
if true || !isfile("plots/supernova_omegas.pdf") || !isfile("plots/supernova_hubble.pdf") || !isfile("plots/supernova_distance.pdf")
    println("Plotting plots/supernova_omegas.pdf")

    data = readdlm("data/supernovadata.txt", comments=true)
    N_obs, _ = size(data)
    z_obs, dL_obs, ??dL_obs = data[:,1], data[:,2], data[:,3]
    x_obs = @. -log(z_obs + 1)

    function logLfunc(params::Vector{Float64})
        h, ??m0, ??k0 = params[1], params[2], params[3]
        co = ??CDM(h=h, ??b0=0.05, ??c0=??m0-0.05, ??k0=??k0, Neff=0)
        if Cosmology.is_fucked(co)
            return -Inf # so set L = 0 (or log(L) = -???, or ??2 = ???)
        else
            dL_mod = Cosmology.dL.(co, x_obs) / Gpc
            return -1/2 * sum((dL_mod .- dL_obs).^2 ./ ??dL_obs.^2) # L = exp(-??2/2)
        end
    end

    hbounds = (0.5, 1.5)
    ??m0bounds = (0.0, 1.0)
    ??k0bounds = (-1.0, +1.0)
    nparams = 3 # h, ??m0, ??k0
    nchains = 10
    nsamples = 10000 # per chain
    params, logL = MetropolisHastings(logLfunc, [hbounds, ??m0bounds, ??k0bounds], nsamples, nchains; burnin=1000)
    h, ??m0, ??k0, ??2 = params[:,1], params[:,2], params[:,3], -2 * logL

    # compute corresponding ???? values by reconstructing the cosmologies (this is computationally cheap)
    ????0 = [??CDM(h=h[i], ??b0=0.05, ??c0=??m0[i]-0.05, ??k0=??k0[i], Neff=0).????0 for i in 1:length(h)]
    ????0bounds = (0.0, 1.2) # just for later plotting

    # best fit
    best_index = argmax(logL)
    best_h, best_??m0, best_??k0, best_????0, best_??2 = h[best_index], ??m0[best_index], ??k0[best_index], ????0[best_index], ??2[best_index]
    println("Best fit (????/N = $(round(best_??2/N_obs, digits=1))): h = $best_h, ??m0 = $best_??m0, ??k0 = $best_??k0")

    # compute 68% ("1??") and 95% ("2??") confidence regions (https://en.wikipedia.org/wiki/Confidence_region)
    # (we have 3D Gaussian, but only for a 1D Gaussian does this correspond to the probability of finding values within 1??/2??!)
    # (see e.g. https://www.visiondummy.com/2014/04/draw-error-ellipse-representing-covariance-matrix/
    #  and      https://stats.stackexchange.com/questions/61273/68-confidence-level-in-multinormal-distributions
    #  and      https://math.stackexchange.com/questions/1357071/confidence-ellipse-for-a-2d-gaussian)
    confidence2 = cdf(Chisq(1), 2^2) # ??? 95% (2?? away from mean of 1D Gaussian)
    confidence1 = cdf(Chisq(1), 1^2) # ??? 68% (1?? away from mean of 1D Gaussian)
    filter2 = ??2 .- best_??2 .< quantile(Chisq(nparams), confidence2) # ??? 95% ("2??" in a 1D Gaussian) confidence region
    filter1 = ??2 .- best_??2 .< quantile(Chisq(nparams), confidence1) # ??? 68% ("1??" in a 1D Gaussian) confidence region
    h2, ??m02, ??k02, ????02 = h[filter2], ??m0[filter2], ??k0[filter2], ????0[filter2]
    h1, ??m01, ??k01, ????01 = h[filter1], ??m0[filter1], ??k0[filter1], ????0[filter1]

    plot(xlabel = L"\Omega_{m0}", ylabel = L"\Omega_{\Lambda}", size = (600, 600), xlims = ????0bounds, ylims = ????0bounds, xticks = range(????0bounds..., step=0.1), yticks = range(????0bounds..., step=0.1), legend_position = :topright)
    #scatter!(??m02, ????02; color = 1, markershape = :rect, markerstrokecolor = 1, markerstrokewidth = 0, markersize = 2.0, clip_mode = "individual", label = L"%$(round(confidence2*100; digits=1)) % \textrm{ confidence region}") # clip mode workaround to get line above scatter points: https://discourse.julialang.org/t/plots-jl-with-pgfplotsx-adds-series-in-the-wrong-order/85896
    #scatter!(??m01, ????01; color = 3, markershape = :rect, markerstrokecolor = 3, markerstrokewidth = 0, markersize = 2.0, clip_mode = "individual", label = L"%$(round(confidence1*100; digits=1)) % \textrm{ confidence region}")
    scatterheatmaps!([??m02, ??m01], [????02, ????01], [palette(:default)[1], :darkblue], [L"%$(round(confidence2*100; digits=1)) \% \textrm{ confidence region}", L"%$(round(confidence1*100; digits=1)) \% \textrm{ confidence region}"], ????0bounds, ????0bounds; nbins=120)

    # plot ????(??m0) for a few flat universes (should give ???? ??? 1 - ??m0)
    ??m0_flat = range(??m0bounds..., length=20)
    ????0_flat = [??CDM(h=best_h, ??b0=0.05, ??c0=??m0-0.05, ??k0=0, Neff=0).????0 for ??m0 in ??m0_flat]
    plot!(??m0_flat, ????0_flat; color = :black, marker = :circle, markersize = 2, label = "flat universes")

    scatter!([best_??m0], [best_????0]; color = :red, markerstrokecolor = :red, markershape = :cross, markersize = 10, label = "our best fit")
    scatter!([0.317], [0.683]; color = :green, markerstrokecolor = :green, markershape = :cross, markersize = 10, label = "Planck 2018's best fit")
    #vline([best_??m0]; linestyle = :dash, color = :red, label = L"\textrm{our best fit}")
    #hline([best_????0]; linestyle = :dash, color = :red)
    savefig("plots/supernova_omegas.pdf")

    # TODO: draw error ellipses?
    # see e.g. https://www.visiondummy.com/2014/04/draw-error-ellipse-representing-covariance-matrix/

    println("Plotting plots/supernova_hubble.pdf")

    nfit = fit(Normal, h) # fit Hubble parameters to normal distribution
    plot(xlabel = L"h = H_0 \,/\, 100\,\frac{\mathrm{km}}{\mathrm{s}\,\mathrm{Mpc}}", ylabel = L"P(h)", xlims = (0.65, 0.75), ylims = (0, 1.1 / ???(2*??*var(nfit))), xticks = 0.65:0.01:0.75, yticks=0:10:100, legend_position = :topright)
    histogram!(h; normalize = true, linewidth = 0, label = L"%$(nchains) \times %$(nsamples) \textrm{ samples}")
    vline!([best_h]; linestyle = :dash, color = :red, label = L"\textrm{our best fit}")
    vline!([0.674]; linestyle = :dash, label = L"\textrm{Planck 2018's best fit}")
    plot!(h -> pdf(nfit, h); color = :black, label = L"N(\mu = %$(round(mean(nfit), digits=2)), \sigma = %$(round(std(nfit), digits=2)))")
    savefig("plots/supernova_hubble.pdf")


    println("Plotting plots/supernova_distance.pdf")
    plot(xlabel = L"\log_{10} \Big[ 1+z \Big]", ylabel = L"d_L \,/\, z \, \mathrm{Gpc}", legend_position = :topleft)

    x2 = range(-1, 0, length=400)
    plot!(log10.(Cosmology.z.(x2).+1), Cosmology.dL.(co, x2) ./ Cosmology.z.(x2) ./ Gpc; color = :green, label = "prediction (Planck 2018)")

    snco = ??CDM(h=best_h, ??b0=0, ??c0=best_??m0, ??k0=best_??k0, Neff=0)
    plot!(log10.(Cosmology.z.(x2).+1), Cosmology.dL.(snco, x2) ./ Cosmology.z.(x2) ./ Gpc; color = :red, label = "prediction (our best fit)")

    data = readdlm("data/supernovadata.txt", comments=true)
    zobs, dL, ??dL = data[:,1], data[:,2], data[:,3]
    err_lo, err_hi = ??dL ./ zobs, ??dL ./ zobs
    scatter!(log10.(zobs.+1), dL ./ zobs; markercolor = :black, yerror = (err_lo, err_hi), markersize=2, label = "supernova observations")

    savefig("plots/supernova_distance.pdf")
end

end
