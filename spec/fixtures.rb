# coding: utf-8
# JSONs stolen from official workable API docs

def about_json_fixture
  read_fixture 'about.json'
end

def jobs_index_json_fixture
  read_fixture 'jobs.json'
end

def job_json_fixture
  read_fixture 'job.json'
end

def job_candidates_json_fixture
  read_fixture 'job_candidates.json'
end

def job_candidate_json_fixture
  read_fixture 'job_candidate.json'
end

def stages_json_fixture
  read_fixture 'stages.json'
end

def job_questions_json_fixture
  read_fixture 'job_questions.json'
end

def recruiters_json_fixture
  read_fixture 'recruiters.json'
end

def members_json_fixture
  read_fixture 'members.json'
end

def new_candiate_hash_fixture
  JSON.parse(read_fixture('new_candidate.json'))
end

def new_candiate_response_json_fixture
  read_fixture 'new_candidate_response.json'
end

def read_fixture(filename)
  File.read File.expand_path("../fixtures/#{filename}", __FILE__)
end
