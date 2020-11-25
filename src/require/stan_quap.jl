import StatsBase: sample
import MonteCarloMeasurements:Particles
import StatisticalRethinking: quap, mode_estimates

function quap(sm::SampleModel)
  s = read_samples(sm; output_format=:dataframe)
  ntnames = (:coef, :vcov, :converged, :distr, :params)
  n = Symbol.(names(s))
  coefnames = tuple(n...,)
  p = mode_estimates(s)
  c = [mean(p[k]) for k in n]
  cvals = reshape(c, 1, length(n))
  coefvalues = tuple(cvals...,)
  v = Statistics.covm(Array(s), cvals)

  distr = if length(coefnames) == 1
    Normal(coefvalues[1], √v[1])  # Normal expects stddev
  else
    MvNormal(coefvalues, v)       # MvNormal expects variance matrix
  end

  ntvalues = tuple(
    namedtuple(coefnames, coefvalues),
    v, true, distr, n
  )

  namedtuple(ntnames, ntvalues)
end

function sample(qm::NamedTuple; nsamples=4000)
  df = DataFrame()
  for coef in qm.params
    df[!, coef] = Particles(nsamples, qm.distr).particles
  end
  df
end

export
  quap,
  Particles,
  sample
