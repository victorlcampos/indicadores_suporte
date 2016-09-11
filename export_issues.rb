require "httparty"

#Vetor de issues
issues = []
chave = 
#response (hash)
response = JSON.parse(HTTParty.get("https://projects.visagio.com/issues.json?key=#{chave}&status_id=*").body)
#chaves disponibilizados na hash response - ["issues", "total_count", "offset", "limit"]
#issues é uma outra hash dentro de response
#forma de acesso a elementos detro da hash objeto["nome da chave"]
total_issues = response["total_count"]
limit = response["limit"]
pages = (total_issues/limit)+1

issues = issues.concat(response["issues"])

(1..(pages-1)).each do |page|

  #offset - pula a quantidade de issues retornadas na requisição
  response = JSON.parse(HTTParty.get("https://projects.visagio.com/issues.json?key=#{chave}&offset=#{page*25}&status_id=*").body)
  issues = issues.concat(response["issues"])

  #/issues//time_entries.json?key=3d5d6acee3580f265adffc2f32d9970c903f8386
  #{"time_entries":[],"total_count":0,"offset":0,"limit":25}
  #/issues/43355/time_entries.json?key=3d5d6acee3580f265adffc2f32d9970c903f8386
end



file_path = File.join('.','issues.csv')
CSV.open(file_path, "wb") do |csv|
  issues.map do |issue|
    {
      id: issue["id"],
      project_name: issue["project"]["name"],
      tracker_name: issue["tracker"]["name"],
      status_name: issue["status"]["name"],
      priority_name: issue["priority"]["name"],
      company_name: (issue["company"] ? issue["company"]["name"] : nil),
      author_name: issue["author"]["name"],
      assigned_to: (issue["assigned_to"] ? issue["assigned_to"]["name"] : nil),
      done_ratio: issue["done_ratio"],
      created_on: issue["created_on"],
      updated_on: issue["updated_on"],
      closed_on: issue["closed_on"],
      start_date: issue["start_date"],
      due_date: issue["due_date"],
      estimated_hours: issue["estimated_hours"]
    }
  end.each do |issue|
    csv << issue.values
  end
end