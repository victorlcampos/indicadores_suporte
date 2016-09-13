require "httparty"
require "parallel"

class RedmineBase
  def self.response(url, key, params)
    JSON.parse(HTTParty.get("#{url}.json?#{params_to_url(key, params)}").body)
  end

  def self.params_to_url(key, params)
    params.merge({key: key}).map { |k,v| "#{k}=#{v}" }.join('&')
  end

  def self.list_all(url, key, params, total, limit, resource_name)
    pages = get_page_num(total, limit)
    p "total de paginas - #{pages}"

    Parallel.map(0..(pages-1)) do |page|
      p page

      #offset - pula a quantidade de issues retornadas na requisição
      response(url, key, params.merge({offset: page*25}))[resource_name]
    end.flatten
  end

  def self.get_page_num(total, limit)
    (total/limit)+1
  end
end

class TimeEntry
  def self.list(issue, key)
    url = "#{Issue::URL}/#{issue}/time_entries"
    spent_response = RedmineBase.response(url, key, {})
    RedmineBase.list_all(url, key, {}, spent_response["total_count"], spent_response["limit"], "time_entries")
  end
end

class Issue
  URL = 'https://projects.visagio.com/issues'.freeze

  def self.list(key, params)
    issue_response = RedmineBase.response(URL, key, params)

    #.map "reescreve" cada elemento do vetor obedecendo a regra definida entre {}
    Parallel.map(RedmineBase.list_all(URL, key, params, issue_response["total_count"], issue_response["limit"], "issues")) do |issue|
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
        estimated_hours: issue["estimated_hours"],
        spent_time: calc_spent_hours(issue["id"], key)
      }
    end
  end

  private

  def self.calc_spent_hours(issue_id, key)
    TimeEntry.list(issue_id, key).map { |te| te['hour'].to_i }.reduce(0, :+) rescue 0
  end
end

#Vetor de issues

file_path = File.join('.','issues.csv')

issues = Issue.list(ENV["REDMINE_KEY"], {status_id: '*'})

CSV.open(file_path, "wb") do |csv|
  #headers
  csv << ["issue_id",
          "project_name",
          "tracker_name",
          "status_name",
          "priority_name",
          "company_name",
          "author_name",
          "assigned_to",
          "done_ratio",
          "created_on",
          "updated_on",
          "closed_on",
          "start_date",
          "due_date",
          "estimated_hours",
          "spent_time"
        ]
  #valores

  p "#Issues: #{issues.count}"

  issues.each do |issue|
    csv << issue.values
  end
end
