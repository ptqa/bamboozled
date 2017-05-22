module Bamboozled
  module API
    class Employee < Base

      def all(fields = nil)
        response = request(:get, "employees/directory")

        if fields.nil? || fields == :default
          Array(response['employees'])
        else
          employees = []
          response['employees'].map{|e| e['id']}.each do |id|
            begin
              employees << find(id, fields)
            rescue => e
            end
          end
          employees
        end
      end

      def find(employee_id, fields = nil)
        fields = all_fields if fields == :all
        fields = fields.join(',') if fields.is_a?(Array)

        request(:get, "employees/#{employee_id}?fields=#{fields}")
      end

      def last_changed(date = "2011-06-05T00:00:00+00:00", type = nil)
        query = Hash.new
        query[:since] = date.respond_to?(:iso8601) ? date.iso8601 : date
        query[:type] = type unless type.nil?

        response = request(:get, "employees/changed", query: query)
        response["employees"]
      end

      # Tabular data
      [:job_info, :employment_status, :compensation, :dependents, :contacts].each do |action|
        define_method(action.to_s) do |argument_id|
          request(:get, "employees/#{argument_id}/tables/#{action.to_s.gsub(/_(.)/) {|e| $1.upcase}}")
        end
      end

      def time_off_estimate(employee_id, end_date)
        end_date = end_date.strftime("%F") unless end_date.is_a?(String)
        request(:get, "employees/#{employee_id}/time_off/calculator?end=#{end_date}")
      end

      def all_fields
        %w(address1 address2 age bestEmail birthday city country dateOfBirth department division eeo employeeNumber employmentHistoryStatus ethnicity exempt firstName flsaCode fullName1 fullName2 fullName3 fullName4 fullName5 displayName gender hireDate homeEmail homePhone id jobTitle lastChanged lastName location maritalStatus middleName mobilePhone nickname payChangeReason payGroup payGroupId payRate payRateEffectiveDate payType ssn sin state stateCode status supervisor supervisorId supervisorEId terminationDate workEmail workPhone workPhonePlusExtension workPhoneExtension zipcode photoUploaded rehireDate standardHoursPerWeek bonusDate bonusAmount bonusReason bonusComment commissionDate commisionDate commissionAmount commissionComment).join(',')
      end

      def photo_binary(employee_id)
        request(:get, "employees/#{employee_id}/photo/small")
      end

      def photo_url(employee)
        if (Float(employee) rescue false)
          e = find(employee, ['workEmail', 'homeEmail'])
          employee = e['workEmail'].nil? ? e['homeEmail'] : e['workEmail']
        end

        digest = Digest::MD5.new
        digest.update(employee.strip.downcase)
        "http://#{@subdomain}.bamboohr.com/employees/photos/?h=#{digest}"
      end

      def add(employee_details)
        details = generate_xml(employee_details)
        options = {body: details}

        request(:post, "employees/", options)
      end

      def update(bamboo_id, employee_details)
        details = generate_xml(employee_details)
        options = { body: details }

        request(:post, "employees/#{bamboo_id}", options)
      end

      private

      def generate_xml(employee_details)
        "".tap do |xml|
          xml << "<employee>"
          employee_details.each { |k, v| xml << "<field id='#{k}'>#{v}</field>" }
          xml << "</employee>"
        end
      end
    end
  end
end
