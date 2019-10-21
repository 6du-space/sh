require! <[
  axios
]>

do ~>
  {data} = await axios.get("https://cdn.jsdelivr.net/npm/6du/package.json")
  {version} = data
  console.log version


