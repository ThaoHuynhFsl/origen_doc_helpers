begin
  require 'origen_testers/atp'
rescue LoadError
  require 'atp'
end
module OrigenDocHelpers
  class ListFlowFormatter < (defined?(OrigenTesters::ATP) ? OrigenTesters::ATP::Formatter : ATP::Formatter)
    attr_reader :html

    def format(node, options = {})
      @html = ''
      process(node)
      html
    end

    def open_table(headers_and_attributes: :default)
      str = ''
      #if headers_and_attributes == :default
      #  str << "<table class=\"table table-hover\">"
      #  str << '<thead><tr>'
      #  str << '<th>Number</th>'
      #  str << '<th>Result</th>'
      #  str << '<th>Test</th>'
      #  str << '<th>Pattern</th>'
      #  str << '<th>Bin</th>'
      #  str << '<th>Softbin</th>'
      #  str << '</tr></thead>'
      #else
      #  str << headers_and_attributes
      #end

      str << "<table class=\"table table-striped\" style=\"table-layout: fixed; width: 100%\">"
      str << "<table class=\"table table-bordered\">"
      str << '<thead><tr>'
      str << '<th>ID</th>'
      str << '<th>HBin</th>'
      str << '<th>SBin</th>'
      str << '<th>Number</th>'
      str << '<th>Test Name</th>'
      str << '<th>Test Pattern</th>'
      str << '<th>Low Limit</th>'
      str << '<th>High Limit</th>'
      str << '<th>Force</th>'
      str << '<th>VDDHV</th>'
      str << '<th>VDDLV</th>'
      str << '<th>Description</th>'
      str << '</tr></thead>'
      str
    end

    def close_table
      '</table>'
    end

    def on_flow(node)
      @flow ||= 0
      @flow += 1
      process_all(node)
    end

    def on_log(node)
      html << "<tr><td colspan=\"6\"><strong>LOG: </strong> #{node.value}</td></tr>"
    end

    def on_render(node)
      html << "<tr><td colspan=\"6\"><strong>RENDER: </strong> An expicitly rendered flow snippet occurs here</td></tr>"
    end

    def on_test(node, body_and_attributes: :default)
      id = node.find(:id).value
      html << "<tr id=\"list_#{@flow}_test_#{id}\" class=\"list-test-line clickable\" data-testid=\"flow_#{@flow}_test_#{id}\">"
      # sequence id
      sequence = node.find(:id).value.gsub('t','').to_i
      html << "<td>#{sequence}</td>"
      # hard bin
      if (f1 = node.find(:on_fail)) && (r1 = f1.find(:set_result)) && (b1 = r1.find(:bin))
        html << "<td>#{b1.value}</td>"
      else
        html << '<td></td>'
      end
      # soft bin
      if (f1 = node.find(:on_fail)) && (r1 = f1.find(:set_result)) && (b1 = r1.find(:softbin))
        html << "<td>#{b1.value}</td>"
      else
        html << '<td></td>'
      end
      # test number
      html << "<td>#{node.find(:number).try(:value)}</td>"
      # test name
      if n = node.find(:name)
        name = n.value
      else
        name = node.find(:object).value['Test']
      end
      html << "<td width=\"35%\" style=\"word-break: break-word\">#{name}</td>"
      html << "<td width=\"20%\" style=\"word-break: break-word\">#{node.find(:object).value['Pattern']}</td>"
      # if no limits found in node
      if node.find_all(:limit).nil? || node.find_all(:limit).empty?
        html << '<td></td>'
        html << '<td></td>' 
      else # found parametric limits in node
        para_limits = node.find_all(:limit)
        u_limit = ''
        u_limit_units = ''
        l_limit = ''
        l_limit_units = ''
        para_limits[0..1].each do |limit|
          if limit.inspect.include?('gte')
            l_limit = '%.4g' % limit.value
          elsif limit.inspect.include?('lte')
            u_limit = '%.4g' % limit.value
          else
            raise 'Cannot idenfity if the value of limit is for upper or lower limit'
          end
        end

        if !node.find_all(:units).empty?
          u_limit_units = node.find_all(:units).first.value 
          l_limit_units = node.find_all(:units).first.value 
        end
        html << "<td>#{l_limit.to_s << l_limit_units}</td>" 
        html << "<td>#{u_limit.to_s << l_limit_units}</td>" 
      end

      # force value
      force_val = ''
      force_val = node.find_all(:force_value).first.value.round(3) if !node.find_all(:force_value).empty? # assume 1 force value for now
      html << "<td>#{force_val}</td>"

      # vddhv and vddlv
      vddhv = ''
      vddlv = ''
      if node.find(:object).value.include?('Vdio')
        vddhv = node.value.fetch('Vdio').to_s.upcase
      else
        vddhv = node.value.fetch('Vddhv').to_s.upcase
      end
      if node.find(:object).value.include?('Vddx')
        vddlv = node.value.fetch('Vddx').to_s.upcase
      else
        vddlv = node.value.fetch('Vddlv').to_s.upcase
      end
      html << "<td>#{vddhv}</td>"
      html << "<td>#{vddlv}</td>"  
      if node.description
        html << "<td width=\"35%\" style=\"word-break: break-word\">#{node.description.join("\n")}</td>" 
      else
        html << '<td></td>' 
      end
      html << '</tr>'
    end

    def on_set_result(node)
      html << '<tr>'
      html << '<td></td>'
      if node.to_a[0] == 'pass'
        html << '<td>PASS</td>'
      else
        html << '<td>FAIL</td>'
      end
      html << '<td></td>'
      html << '<td></td>'
      html << "<td>#{node.find(:bin).try(:value)}</td>"
      html << "<td>#{node.find(:softbin).try(:value)}</td>"
      html << '</tr>'
    end
  end
end
