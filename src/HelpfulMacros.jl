module Macros

export @elidableassert, @elidableenv, @elidablenanzeroer, @timeandfilepath

"""
Show the environment variables
"""
macro elidableenv()
  quote
    filter(x -> occursin("ELIDE", first(x)), $ENV)
  end
end


"""
The Julia @assert macro, except it can be compiled by one of two ways:
1) Set `ENV["ELIDE_ASSERTS"]` to one of `"yes"`, `"true"`, `"1"`, or `"on"`
or
2) Put the function `elideasserts() = true` in the module that calls @elidableassert
but not both
"""
macro elidableassert(assertion, messages...)
  local elide = haskey(ENV, "ELIDE_ASSERTS") &&
    ENV["ELIDE_ASSERTS"] ∈ ("yes", "true", "1", "on");
  elide |= @isdefined(elideasserts) ? elideasserts() : false;
  if @isdefined(elideasserts) && haskey(ENV, "ELIDE_ASSERTS") &&
    ENV["ELIDE_ASSERTS"] ∈ ("yes", "true", "1", "on");
    error("Set only ENV[\"ELIDE_ASSERTS\"] or elideasserts(), not both.");
  end
  if !elide
    quote
      if !isempty($(esc(messages)))
        @assert $(esc(assertion)) $(esc(messages))
      else
        @assert $(esc(assertion))
      end
    end
  end
end

"""
Replace NaNs with zeros
Compile out this macro by one of two ways:
1) Set `ENV["ELIDE_NANZEROER"]` to one of `"yes"`, `"true"`, `"1"`, or `"on"`
or
2) Put the function `elidenanzeroer() = false` in the module that calls @elidablenanzeroer
but not both
"""
macro elidablenanzeroer(value)
  local elide = haskey(ENV, "ELIDE_NANZEROER") &&
    ENV["ELIDE_NANZEROER"] ∈ ("yes", "true", "1", "on");
  elide |= @isdefined(elidenanzeroer) ? elidenanzeroer() : false;
  if @isdefined(elidenanzeroer) && haskey(ENV, "ELIDE_NANZEROER") &&
    ENV["ELIDE_NANZEROER"] ∈ ("no", "false", "0", "off");
    error("Set only ENV[\"ELIDE_NANZEROER\"] or elidenanzeroer(), not both.");
  end;
  if !elide
    return quote
      @inline _replace(x::T) where {T<:Real} = ifelse(isnan(x), zero(T), x);
      @inline function _replace(x::T) where {T<:Complex};
      r, i = reim(x);
      br = isnan(r);
      bi = isnan(i);
      (!br && !bi) && return x;
      (!br && bi) && return T(r, 0);
      (br && !bi) && return T(0, i);
      (br && bi) && return T(0, 0);
      end;
      _replace.($(esc(value)))
    end
  else
    return quote $(esc(value)) end
  end
end

"""
Display the time, and the file path
"""
macro timeandfilepath()
  quote
    using Dates; println("$(now()) $(@__FILE__)")
  end
end

end
