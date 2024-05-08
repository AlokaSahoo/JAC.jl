
"""
`module  JAC.BeamPhotoExcitation`  
	... a submodel of JAC that contains all methods for computing photo-excitation properties and observables in (twisted) beams
	    of different types. Although organized as atomic computations, similar to the (standard) photoexcitation lines, 
	    emphasis is normally placed on a single transition but the analysis/comparison of different beam types and/or 
	    observables in such a beam.
"""
module BeamPhotoExcitation


using Printf, ..AngularMomentum, ..Basics,  ..Basics,  ..Beam, ..Defaults, ..ManyElectron, ..Nuclear, ..Radial, 
        ..PhotoEmission, ..TableStrings

"""
`struct  BeamPhotoExcitation.Settings  <:  AbstractProcessSettings`  
    ... defines a type for the details and parameters of computing photo-excitation  lines.

    + beamType                ::Beam.AbstractBeamType   ... type of the incoming beam, including their QN and superpositions.
    + observable              ::Beam.AbstractObservable ... type of the observable to be analyzed.
    + multipoles              ::Array{EmMultipole,1}    ... Specifies the multipoles of the radiation field that are to be included.
    + gauges                  ::Array{UseGauge,1}       ... Specifies the gauges to be included into the computations.
    + printBefore             ::Bool                    ... True, if all energies and lines are printed before their evaluation.
    + lineSelection           ::LineSelection           ... Specifies the selected levels, if any.
    + photonEnergyShift       ::Float64                 ... An overall energy shift for all photon energies.
"""
struct Settings  <:  AbstractProcessSettings 
    beamType                  ::Beam.AbstractBeamType
    observable                ::Beam.AbstractObservable 
    multipoles                ::Array{EmMultipole,1}
    gauges                    ::Array{UseGauge,1}
    printBefore               ::Bool 
    lineSelection             ::LineSelection
    photonEnergyShift         ::Float64
end 


"""
`BeamPhotoExcitation.Settings()`  ... 'empty' constructor for the default values of beam-photo-excitation computations.
"""
function Settings()
    Settings(Beam.LaguerreGauss(), Beam.NoObservable(), EmMultipole[], UseGauge[], false, LineSelection(), 0.)
end


"""
`PhotoExcitation.Settings(set::BeamPhotoExcitation.Settings;`

        beamType=..,            observable=..,              multipoles=..,          gauges=..,                  
        printBefore=..,         lineSelection=..,           photonEnergyShift=..)
                    
    ... constructor for modifying the given PhotoExcitation.Settings by 'overwriting' the previously selected parameters.
"""
function Settings(set::BeamPhotoExcitation.Settings;    
    beamType::Union{Missing,Array{EmMultipole,1}}=missing,          observable::Union{Missing,Array{UseGauge,1}}=missing,  
    multipoles::Union{Missing,Array{EmMultipole,1}}=missing,        gauges::Union{Missing,Array{UseGauge,1}}=missing,  
    printBefore::Union{Missing,Bool}=missing,                       lineSelection::Union{Missing,LineSelection}=missing, 
    photonEnergyShift::Union{Missing,Float64}=missing)  

    if  beamType            == missing   beamTypex            = set.beamType                else  beamTypex            = beamType              end 
    if  observable          == missing   observablex          = set.observable              else  observablex          = observable            end 
    if  multipoles          == missing   multipolesx          = set.multipoles              else  multipolesx          = multipoles            end 
    if  gauges              == missing   gaugesx              = set.gauges                  else  gaugesx              = gauges                end 
    if  printBefore         == missing   printBeforex         = set.printBefore             else  printBeforex         = printBefore           end 
    if  lineSelection       == missing   lineSelectionx       = set.lineSelection           else  lineSelectionx       = lineSelection         end 
    if  photonEnergyShift   == missing   photonEnergyShiftx   = set.photonEnergyShift       else  photonEnergyShiftx   = photonEnergyShift     end 
    
    Settings( beamTypex, observablex, multipolesx, gaugesx, printBeforex, lineSelectionx, photonEnergyShiftx)
end


# `Base.show(io::IO, settings::BeamPhotoExcitation.Settings)`  ... prepares a proper printout of the variable settings::BeamPhotoExcitation.Settings.
function Base.show(io::IO, settings::BeamPhotoExcitation.Settings) 
    println(io, "beamType:                 $(settings.beamType)  ")
    println(io, "observable:               $(settings.observable)  ")
    println(io, "multipoles:               $(settings.multipoles)  ")
    println(io, "use-gauges:               $(settings.gauges)  ")
    println(io, "printBefore:              $(settings.printBefore)  ")
    println(io, "lineSelection:            $(settings.lineSelection)  ")
    println(io, "photonEnergyShift:        $(settings.photonEnergyShift)  ")
end


"""
`struct  BeamPhotoExcitation.Outcome`  
    ... defines a type for an outcome of photo-excitation study/observable within a (twisted) beam; it comprises 
        all information about the initial and final levels, the beam type as well as the coordinates and calculated 
        values for this observable.

    + initialLevel   ::Level                         ... initial-(state) level
    + finalLevel     ::Level                         ... final-(state) level
    + omega          ::Float64                       ... Transition frequency of this line; can be shifted w.r.t. the level energies.
    + beamType       ::Beam.AbstractBeamType         ... type of the incoming beam, including their QN and superpositions.
    + observable     ::Beam.AbstractObservable       ... type of the observable to be analyzed.
    + fieldValues    ::Array{Basics.AbstractFieldValue,1}  
        ... List of field values f(x1, x2, ...) of the given observable whose type and parametrization (x1, x2, ...) 
            depend on the given parameters. In particular, the physical interpretation of these values refer to this 
            type and parametrization. Examples are: scalar f(x,y), scalar f(r,theta,phi), vector tuple f(x,y), ...
"""
struct  Outcome
    initialLevel     ::Level 
    finalLevel       ::Level
    omega            ::Float64  
    beamType         ::Beam.AbstractBeamType 
    observable       ::Beam.AbstractObservable 
    fieldValues      ::Array{Basics.AbstractFieldValue,1}  
end 


"""
`BeamPhotoExcitation.Outcome()`  
    ... constructor for an 'empty' beam-photo-excitation outcome for a specified initial and final level.
"""
function Outcome()
    Outcome( Level(), Level(), 0., Beam.LaguerreGauss(), Beam.NoObservable(), Basics.Cartesian2DFieldValue{Float64}[] )
end


# `Base.show(io::IO, outcome::BeamPhotoExcitation.Outcome)`  ... prepares a proper printout of the variable outcome::BeamPhotoExcitation.Outcome.
function Base.show(io::IO, outcome::BeamPhotoExcitation.Outcome) 
    println(io, "initialLevel:         $(outcome.initialLevel)  ")
    println(io, "finalLevel:           $(outcome.finalLevel)  ")
    println(io, "omega:                $(outcome.omega)  ")
    println(io, "beamType:             $(outcome.beamType)  ")
    println(io, "observable:           $(outcome.observable)  ")
    println(io, "fieldValues:          $(outcome.fieldValues)  ")
end


"""
`BeamPhotoExcitation.absorptionAmplitude()`  
    ... to compute the absorption amplitude for ...
"""
function  absorptionAmplitude()
    wa = ComplexF64(1.)
    println("BeamPhotoExcitation.absorptionAmplitude() ... not yet implemented.")
    return( wa )
end


"""
`BeamPhotoExcitation.computeOutcome(observable::Beam.DominantMultipoles, outcome::BeamPhotoExcitation.Outcome, nm::Nuclear.Model, 
                                    grid::Radial.Grid, settings::BeamPhotoExcitation.Settings)`  
    ... to compute the field values for the observable::Beam.DominantMultipoles and the parameters, given by the (initialized)
        outcome and the settings. An outcome::BeamPhotoExcitation.Outcome is returned.
"""
function  computeOutcome(observable::Beam.DominantMultipoles, outcome::BeamPhotoExcitation.Outcome, nm::Nuclear.Model, 
                            grid::Radial.Grid, settings::BeamPhotoExcitation.Settings)
    println("BeamPhotoExcitation.computeOutcome(), observable = $(observable) ... not yet implemented.")
    return(outcome)
end


"""
`BeamPhotoExcitation.computeOutcomes(finalMultiplet::Multiplet, initialMultiplet::Multiplet, nm::Nuclear.Model, 
                                        grid::Radial.Grid, settings::BeamPhotoExcitation.Settings; output::Bool=true)`  
    ... to compute all selected outcomes for the photo-excitation of atoms in (twisted) beams as requested by the given
        settings.
"""
function  computeOutcomes(finalMultiplet::Multiplet, initialMultiplet::Multiplet, nm::Nuclear.Model, 
                            grid::Radial.Grid, settings::BeamPhotoExcitation.Settings; output::Bool=true)
    printSummary, iostream = Defaults.getDefaults("summary flag/stream")
    
    println("")
    printstyled("BeamPhotoExcitation.computeOutcomes(): The computation of the observable starts now ... \n", color=:light_green)
    printstyled("--------------------------------------------------------------------------------------- \n", color=:light_green)
    println("")
    #
    outcomes = BeamPhotoExcitation.determineOutcomes(finalMultiplet, initialMultiplet, settings)
    # Display all selected lines before the computations start
    if  settings.printBefore    
        for  outcome in outcomes  BeamPhotoExcitation.displaySelectedOutcome(stdout, outcome)    end
    end
    #
    newOutcomes = BeamPhotoExcitation.Outcome[]
    for  outcome in outcomes
        println("\n>> Calculate outcome for line: $(outcome.initialLevel.index) - $(outcome.finalLevel.index) " *
                "for the photon energy $(Defaults.convertUnits("energy: from atomic", outcome.omega)) " * Defaults.GBL_ENERGY_UNIT)
        newOutcome = BeamPhotoExcitation.computeOutcome(outcome.observable, outcome, nm, grid, settings) 
        push!( newOutcomes, newOutcome)
    end
    # Print all results to screen
    for  outcome in outcomes  BeamPhotoExcitation.displayOutcome(stdout, outcome.observable, outcome, settings)    end
    if  printSummary 
        for  outcome in outcomes  BeamPhotoExcitation.displayOutcome(iostream, outcome.observable, outcome, settings)    end
    end
    #
    if    output    return( outcomes )
    else            return( nothing )
    end
end


"""
`BeamPhotoExcitation.determineOutcomes(finalMultiplet::Multiplet, initialMultiplet::Multiplet, settings::BeamPhotoExcitation.Settings)`  
    ... to determine a list of BeamPhotoExcitation.Outcome's for transitions between levels from the initial- and final-state 
        multiplets, and  by taking into account the particular selections and settings for this computation; 
        an Array{BeamPhotoExcitation.Outcome,1} is returned. Apart from the level specification, the choice of the beam type and 
        the selected observable as well as meshes, the (field) values of the observable are set to zero during this initialization 
        process. A list of outcomes::Array{BeamPhotoExcitation.Outcome,1} is returned.
"""
function  determineOutcomes(finalMultiplet::Multiplet, initialMultiplet::Multiplet, settings::BeamPhotoExcitation.Settings)
    newOutcomes = BeamPhotoExcitation.Outcome[]
    for  iLevel  in  initialMultiplet.levels
        for  fLevel  in  finalMultiplet.levels
            if  Basics.selectLevelPair(iLevel, fLevel, settings.lineSelection)
                omega = fLevel.energy - iLevel.energy
                if  omega < 0.    continue   end
                fieldCoordinates = Basics.generateFieldCoordinates(settings.observable.mesh)
                outcome = BeamPhotoExcitation.Outcome(iLevel, fLevel, omega, settings.beamType, settings.observable,   
                                                        fieldCoordinates )
                push!( newOutcomes, outcome )
            end
        end
    end
    
    return(newOutcomes)
end


"""
`BeamPhotoExcitation.displayOutcome(stream::IO, observable::Beam.DominantMultipoles, outcome::Outcome, 
                                    settings::BeamPhotoExcitation.Settings)`  
    ... to display the outcome for the observable::Beam.DominantMultipoles in some neat table; nothing is returned.
"""
function  displayOutcome(stream::IO, observable::Beam.DominantMultipoles, outcome::Outcome, settings::BeamPhotoExcitation.Settings)
    function  fvString(fv::Basics.AbstractFieldValue)
        sc = "("
        for  fn in fieldnames( typeof(fv) )   
            sc = sc * @sprintf("%.4e", getfield(fv, fn)) * ", "
        end
        return( sc[1:end-2] * ")" )
    end
    # Prepare strings to print the names of coordinates and the first and last few coordinates explicitly
    sa = "(";  sb = " "
    for  fn in fieldnames( typeof(outcome.fieldValues[1]) )   sa = sa * string(fn) * ", "   end;     sa = sa[1:end-2] * ")"
    for  (f,fv) in  enumerate(outcome.fieldValues)
        if      f <  5   sb = sb * fvString(fv) * "  "
        elseif  f == 5   sb = sb * "    ...  \n    "
        elseif  f >  length(outcome.fieldValues) - 4    sb = sb * fvString(fv) * "  "
        end 
    end
    symi = LevelSymmetry(outcome.initialLevel.J, outcome.initialLevel.parity)
    symf = LevelSymmetry(outcome.finalLevel.J,   outcome.finalLevel.parity)
    #
    println(stream, " ")
    println(stream, "  BeamPhotoExcitation computations will be performed for: \n" *
                    "  ------------------------------------------------------- \n" *
                    "  + Transition with symmetries:   $(outcome.initialLevel.index) --> $(outcome.finalLevel.index)    " *
                    "  [$(symi) --> $(symf)]  \n"                                  *
                    "  + Omega:                        " * 
                    @sprintf("%.4e", Defaults.convertUnits("energy: from atomic", outcome.omega)) * 
                    "  " * TableStrings.inUnits("energy") * "  \n" *
                    "  + Beam (type):                  $(typeof(outcome.beamType))        \n" *
                    "  + Observable (type):            $(typeof(outcome.observable))      \n" *
                    "  + Field values at:              $sa    \n   $sb" )
    
    return(nothing)
end


"""
`BeamPhotoExcitation.displaySelectedOutcome(stream::IO, outcome::Outcome)`  
    ... to display prior to the computations the basic information about this outcome,  the chosen mesh types and 
        the explicit coordinates of the computation. Apart from this short summary, nothing is returned.
"""
function  displaySelectedOutcome(stream::IO, outcome::Outcome)
    function  fvString(fv::Basics.AbstractFieldValue)
        sc = "("
        for  fn in fieldnames( typeof(fv) )   
            if  fn != :val    sc = sc * @sprintf("%.4e", getfield(fv, fn)) * ", "   end
        end
        return( sc[1:end-2] * ")" )
    end
    # Prepare strings to print the names of coordinates and the first and last few coordinates explicitly
    sa = "(";  sb = " "
    for  fn in fieldnames( typeof(outcome.fieldValues[1]) )   
        if  fn != :val   sa = sa * string(fn) * ", "   end   
    end;     sa = sa[1:end-2] * ")"
    for  (f,fv) in  enumerate(outcome.fieldValues)
        if      f <  5   sb = sb * fvString(fv) * "  "
        elseif  f == 5   sb = sb * "    ...   \n    "
        elseif  f >  length(outcome.fieldValues) - 4    sb = sb * fvString(fv) * "  "
        end 
    end
    symi = LevelSymmetry(outcome.initialLevel.J, outcome.initialLevel.parity)
    symf = LevelSymmetry(outcome.finalLevel.J,   outcome.finalLevel.parity)
    #
    println(stream, " ")
    println(stream, "  BeamPhotoExcitation computations will be performed for: \n" *
                    "  ------------------------------------------------------- \n" *
                    "  + Transition with symmetries:   $(outcome.initialLevel.index) --> $(outcome.finalLevel.index)    " *
                    "  [$(symi) --> $(symf)]  \n"                                  *
                    "  + Omega:                        " * 
                    @sprintf("%.4e", Defaults.convertUnits("energy: from atomic", outcome.omega)) * 
                    "  " * TableStrings.inUnits("energy") * "  \n" *
                    "  + Beam (type):                  $(typeof(outcome.beamType))        \n" *
                    "  + Observable (type):            $(typeof(outcome.observable))      \n" *
                    "  + Field values at:              $sa    \n   $sb" )
    
    return(nothing)
end


end # module

