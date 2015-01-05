# coding: utf-8
# dead-simple methods instead of full vcr cassettes, because why not?

def jobs_index_json_fixture
  JSON.generate({
    "name" => "wojsznis",
    "description" => nil,
    "jobs" => [
      {
        "key" => "7c60",
        "title" => "Ruby on Rails dev",
        "full_title" => "Ruby on Rails dev - CODE",
        "code" => "CODE",
        "shortcode" => "03FF356C8B",
        "state" => "published",
        "department" => "DEPT",
        "url" => "https://wojsznis.workable.com/jobs/30606",
        "application_url" => "https://wojsznis.workable.com/jobs/30606/candidates/new",
        "shortlink" => "https://wojsznis.workable.com/j/03FF356C8B",
        "location" => {
          "country" => "Poland",
          "country_code" => "PL",
          "region" => "Małopolskie",
          "region_code" => "MA",
          "city" => "Kraków",
          "zip_code" => "30-000",
          "telecommuting" => true
        },
        "created_at" => "2015-01-05"
      }
    ]
})
end

def job_json_fixture
  JSON.generate({
    "key" => "7c60",
    "title" => "Ruby on Rails dev",
    "full_title" => "Ruby on Rails dev - CODE",
    "code" => "CODE",
    "shortcode" => "03FF356C8B",
    "state" => "draft",
    "department" => "DEPT",
    "url" => "https://wojsznis.workable.com/jobs/30606",
    "application_url" => "https://wojsznis.workable.com/jobs/30606/candidates/new",
    "shortlink" => "https://wojsznis.workable.com/j/03FF356C8B",
    "location" => {
      "country" => "Poland",
      "country_code" => "PL",
      "region" => "Małopolskie",
      "region_code" => "MA",
      "city" => "Kraków",
      "zip_code" => "30-338",
      "telecommuting" => true
    },
    "created_at" => "2015-01-05",
    "full_description" => "<p>Example job brief.</p>\r\n<ul>\n<li>test 1</li>\r\n<li>test 2</li>\r\n<li>test 3</li>\r\n</ul><p></p>\r\n<p><b>End of test.</b></p><p><strong>Requirements</strong></p><ul>\n<li>req 1</li>\r\n<li>req 2</li>\r\n</ul><p><strong>Benefits</strong></p><ul>\n<li>ben 1</li>\r\n<li>ben 2</li>\r\n</ul>",
    "description" => "<p>Example job brief.</p>\r\n<ul>\n<li>test 1</li>\r\n<li>test 2</li>\r\n<li>test 3</li>\r\n</ul><p></p>\r\n<p><b>End of test.</b></p>",
    "requirements" => "<ul>\n<li>req 1</li>\r\n<li>req 2</li>\r\n</ul>",
    "benefits" => "<ul>\n<li>ben 1</li>\r\n<li>ben 2</li>\r\n</ul>",
    "employment_type" => "Full-time",
    "industry" => "Information Technology and Services",
    "function" => "Engineering",
    "experience" => "Mid-Senior level",
    "education" => "Professional"
  })
end

def job_candidates_json_fixture
  JSON.generate({
    "candidates" => [
      {
        "key" => "f7087",
        "name" => "Test LastName",
        "firstname" => "Test",
        "lastname" => "LastName",
        "headline" => "headline",
        "account" => {
          "subdomain" => "wojsznis",
          "name" => "wojsznis"
        },
        "job" => {
          "shortcode" => "03FF356C8B",
          "title" => "Ruby on Rails dev"
        },
        "stage" => "Applied",
        "disqualified" => false,
        "sourced" => false,
        "profile_url" => "http://wojsznis.workable.com/backend/jobs/30606/candidates/1010613",
        "address" => "Address",
        "phone" => "",
        "email" => "example@test.com",
        "outbound_mailbox" => "eaqpdpbc@outbound.workablemail.com",
        "domain" => "unknown",
        "created_at" => "2015-01-05 11:56:40",
        "updated_at" => "2015-01-05 11:56:48",
        "cover_letter" => "",
        "summary" => "",
        "education_entries" => [ ],
        "experience_entries" => [ ],
        "skills" => [ ],
        "answers" => [
          {
            "question" => {
                "body" => "Why you want this job?"
            },
            "answer" => {
                "body" => "<p>Sample answer</p>"
            }
          }
        ],
        "resume_url" => "",
        "tags" => [ ]
      }
    ]
  })
end
