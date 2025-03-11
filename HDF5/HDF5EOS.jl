# Open text based EOS files, read in the data, and write each EOS out to a common HDF file

using HDF5
using DelimitedFiles
using ArgParse

# Dictionary of Tabulated EOS names and additional information
eosnames = [Dict("Name"=>"FPS",
				 "Reference"=>"https://doi.org/10.1103/PhysRevLett.70.379",
				 "Description"=>"UV14+TNI",
				 "BaryonMass"=>1.659e-24,
				 "PhaseTransition"=>false),
			Dict("Name"=>"A",
				 "Reference"=>"https://doi.org/10.1016/0375-9474(71)90413-1",
				 "Description"=>"Reid soft core",
				 "BaryonMass"=>1.659e-24,
				 "PhaseTransition"=>false),
			Dict("Name"=>"M",
				 "Reference"=>"https://doi.org/10.1016/0375-9474(75)90415-7",
				 "Description"=>"Tensor interaction",
				 "BaryonMass"=>1.659e-24,
				 "PhaseTransition"=>true,
				 "TransitionIndices"=>[378 379;]),
            Dict("Name"=>"AU",
				 "Reference"=>"https://doi.org/10.1103/PhysRevC.38.1010",
				 "Description"=>"AV14+UVII",
				 "BaryonMass"=>1.659e-24,
				 "PhaseTransition"=>false),
            Dict("Name"=>"B",
				 "Reference"=>"https://doi.org/10.1016/0375-9474(71)90193-X",
				 "Description"=>"Reid code with hyperons",
				 "BaryonMass"=>1.659e-24,
				 "PhaseTransition"=>false),
            Dict("Name"=>"C",
				 "Reference"=>"https://doi.org/10.1016/0375-9474(74)90528-4",
				 "Description"=>"Bethe and Johnson (1974), model I",
				 "BaryonMass"=>1.659e-24,
				 "PhaseTransition"=>false),
            Dict("Name"=>"D",
				 "Reference"=>"https://doi.org/10.1016/0375-9474(74)90528-4",
				 "Description"=>"Bethe and Johnson (1974), model V",
				 "BaryonMass"=>1.659e-24,
				 "PhaseTransition"=>false),
            Dict("Name"=>"E",
				 "Reference"=>"https://doi.org/10.1103/PhysRevD.9.1613",
				 "Description"=>"Moszkowski (1974)",
				 "BaryonMass"=>1.659e-24,
				 "PhaseTransition"=>false),
            Dict("Name"=>"F",
				 "Reference"=>"https://doi.org/10.1016/0375-9474(72)90515-5",
				 "Description"=>"Arponen (1972)",
				 "BaryonMass"=>1.659e-24,
				 "PhaseTransition"=>false),
            Dict("Name"=>"G",
				 "Reference"=>"https://doi.org/10.1103/PhysRevD.9.1587",
				 "Description"=>"Canuto and Chitre (1974)",
				 "BaryonMass"=>1.659e-24,
				 "PhaseTransition"=>false),
            Dict("Name"=>"L",
				 "Reference"=>"https://doi.org/10.1016/0370-2693(75)90143-4",
				 "Description"=>"Mean field",
				 "BaryonMass"=>1.659e-24,
				 "PhaseTransition"=>false),
            Dict("Name"=>"N",
				 "Reference"=>"https://doi.org/10.1016/0370-2693(79)90804-9",
				 "Description"=>"Relativistic mean field",
				 "BaryonMass"=>1.659e-24,
				 "PhaseTransition"=>false),
            Dict("Name"=>"UU",
				 "Reference"=>"https://doi.org/10.1103/PhysRevC.38.1010",
				 "Description"=>"UV14+UVII",
				 "BaryonMass"=>1.659e-24,
				 "PhaseTransition"=>false),
            Dict("Name"=>"UT",
				 "Reference"=>"https://doi.org/10.1103/PhysRevC.38.1010",
				 "Description"=>"UV14+TNI",
				 "BaryonMass"=>1.659e-24,
				 "PhaseTransition"=>false)]

# Set defaults for the HDFfilename and TextPath, then override from input arguments
HDFfilename="Tabulated_EOS.h5"
TextPath=".."

# set up and parse input arguments
aps = ArgParseSettings("Convert text based EOS files (located in {TEXT_PATH}) to HDF5 format and store them in {FILENAME}",
					   version="1.0",add_version=true)
@add_arg_table aps begin
	"--filename"
	help = "Name of the HDF5 file containing the tabulated EOS"
	arg_type = String
	default = HDFfilename
	"--text_path"
	arg_type = String
	help = "Path to the directory containing the EOS text files"
	default = TextPath
	"--remove"
	help = "comma separated list of EOS names to remove from {FILENAME} before exiting.  Result is in Updated{FILENAME}."
	arg_type = String
end
parsed_args = parse_args(ARGS,aps)

if haskey(parsed_args,"filename")
	HDFfilename=parsed_args["filename"]
end
if haskey(parsed_args,"text_path")
	TextPath=parsed_args["text_path"]*"/EOS."
end
# Remove selected EOS by copying all EOS that are not being removed.
if haskey(parsed_args,"remove")
	removeEOS=parsed_args["remove"]
	if removeEOS != nothing
		try 
			h5open(HDFfilename,"r") do h5f # Open the existing HDF file
				try 
					h5open("Updated"*HDFfilename,"w") do h5rm # Open a new file for the truncated set
						rmEOSgroup = Set(strip.(split(removeEOS,","))) # Set of EOS to omit from new file
						EOSgroups = read(h5f) # get a Dictionary of top level groups and their data sets
						for group in keys(EOSgroups)
							if !in(group,rmEOSgroup) # copy the group if the EOS is not being deleted
								try
									eosgroup = create_group(h5rm,group) # create the group in the new file
									for dataset in keys(EOSgroups[group]) # copy all the data sets
										write_dataset(eosgroup,dataset,EOSgroups[group][dataset])
									end
									EOSgrpattrs = attrs(h5f[group]) # copy all the attributes
									for grpatt in keys(EOSgrpattrs)
										write_attribute(eosgroup,grpatt,EOSgrpattrs[grpatt])
									end
								catch
									println("Couldn't copy EOS ",group)
									exit()
								end
							end
						end
					end
				catch
					println("Couldn't create ","Updated"*HDFfilename)
					exit()
				end
			end
		catch
			println("Couldn't open ",HDFfilename)
			exit()
		end
		exit()
	end
end

# loop over all EOS in the EOS dictionary
for eos in eosnames
	filename = TextPath*eos["Name"]
	if !isfile(filename)
		println("Couldn't find ",filename)
		exit()
	end
	println("Converting ",filename," to HDF5")
	eostable = readdlm(filename)	

	try
		# create or open the file, but don't remove existing entries
		h5open(HDFfilename,"cw") do h5f 
			# Create an HDF Group for each EOS
			try
				eosgroup = create_group(h5f,eos["Name"])
				# Store the Tabulated EOS values; Note Julia is column major, so transpose the array
				write_dataset(eosgroup,"Table",permutedims(eostable))
				# Save the name as an attribute
				write_attribute(eosgroup,"EOS Name",eos["Name"])
				# Save the baryon mass
				write_attribute(eosgroup,"BaryonMass",eos["BaryonMass"])
				# Does the EOS contain phase transitions
				write_attribute(eosgroup,"PhaseTransition",eos["PhaseTransition"])
				if eos["PhaseTransition"]
					# store matrix of transition indices in the format [t1i t1f; t2i t2f; t3i t3f; ...]
					# Note Julia is column major, so transpose the array
					write_attribute(eosgroup,"TransitionIndices",permutedims(eos["TransitionIndices"]))
				else
					# make sure that there are no phase transitions in the EOS
					pressure = eostable[:,3]
					consecutiveP = Float64[]
					indices = Vector{Int64}[]
					for i=2:length(pressure)
						if pressure[i-1]==pressure[i]
							push!(consecutiveP,pressure[i])
							push!(indices,[i-1,i])
						end
					end
					if length(consecutiveP)>0
						println("Consecutive pressure entries found indicating phase transitions are present "*
							    " in EOS ",eos["Name"])
						println("Duplicated pressures: ",consecutiveP)
						println("Transition Indices: ",indices)
						println("Store the indices in the TransitionIndices attribute and set the PhaseTransition attribute to true")
						exit()
					end
				end
				# Store a reference for the EOS; preferably a DOI
				write_attribute(eosgroup,"Reference",eos["Reference"])
				# Store additional description of the EOS
				write_attribute(eosgroup,"Description",eos["Description"])
				# Document the columns
				write_attribute(eosgroup,"Column 1","Log10(Baryon number density) - [cm^(-3)];")
				write_attribute(eosgroup,"Column 2","Log10(Total energy density) - [g cm^(-3)]")
				write_attribute(eosgroup,"Column 3","Log10(Pressure) - [dyne cm^(-2)]")
			catch
				println("EOS ",eos["Name"]," already exists in Tabulated_EOS.h5.  Remove to update.")
			end
		end
	catch
		println("./Tabulated_EOS.h5 failed to open or write")
		exit()
	end
end