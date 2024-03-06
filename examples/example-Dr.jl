
#
println("Dr)  Test of the ParticleScattering module with ASF from an internally generated initial and final-state multiplet.")
#
setDefaults("print summary: open", "zzz-ParticleScattering.sum")
setDefaults("unit: energy", "eV")
setDefaults("unit: rate", "1/s")


grid = Radial.Grid(Radial.Grid(false), rnt = 4.0e-6, h = 5.0e-2, hp = 0.6e-2, rbox = 10.0)

if  true
    # Elastic scattering of non-relativistic plane-wave electrons at helium ^1S_0 ground level
    beamType   = Beam.PlaneWave(0., 0., 2.)
    ## beamType   = Beam.BesselBeam(2, 0.1, 2.)
    psSettings = ParticleScattering.Settings(ParticleScattering.ElasticElectronNR(), beamType, Basics.LinearPolarization(),
                                             [1.0, 2.0], [pi/4., pi/2.], [0.], true, LineSelection(), 2)
    wc = Atomic.Computation(Atomic.Computation(), name="Electron scattering", grid=grid, nuclearModel=Nuclear.Model(2.01), 
                            initialConfigs  = [Configuration("1s^2")],
                            finalConfigs    = [Configuration("1s^2")],  
                            processSettings = psSettings )
    ## @show wc
    wd = perform(wc)
elseif  false
end
    
