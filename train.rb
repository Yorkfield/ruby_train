require 'rubygems'
require 'tree'
class Array
    def index_id(id)
        self.each do |node|
            return node if node.id == id
        end
    end
    def find_first_empty
        speed_per_weight = Array.new()
        self.each do |node|
            speed_per_weight << node.enq_real.to_f / node.weight
        end
        return speed_per_weight.index(speed_per_weight.min)
    end
    def sum_weight
        weight_sum = 0
        self.each do |node|
            weight_sum += node.weight
        end
        return weight_sum
    end
end

class Sch < Tree::TreeNode
    include Comparable
    attr_accessor :enq, :sch_type, :weight, :deq, :cir, :eir
    attr_reader :id, :enq_real, :child, :node_type
    def initialize(name)
        super(name)
        @node_type = name.match(/(\w+)_(\d+)/)[1]
        @id = name.match(/(\w+)_(\d+)/)[2].to_i
        @child = Array.new()
        @enq = 0
        @deq = 0
        @sch_type = 'wrr'
        @weight = 1
        @cir = 'max'
        @eir = 'max'
    end
    def <=>(other)
        self.id <=> other.id
    end
    def succ
        Sch.new(@node_type + "_#{@id.succ}")
    end
    def cfg_shp
    end

    # 3.calculate enqueue
    def cal_enq
        if (@cir == 'max') or (@eir == 'max')
            @enq_real = @enq
        else
            if @enq > (@cir + @eir)
                @enq_real = (@cir + @eir)
            else
                @enq_real = @enq
            end
        end
        return self
    end

    # 4.upload enqueue to father
    def upload_enq
        if @node_type == 'root'
            @deq = @enq_real
        else
            @father.enq += @enq_real
        end
    end

    # 5.update dequeue to childs
    def update_deq
        case @sch_type
        when 'sp' then sch_sp
        when 'wrr' then sch_wrr
        end
    end
    def sch_sp
        deq_remain = @deq
        @child.each do |node|
            if node.enq_real < deq_remain
                node.deq = node.enq_real
            elsif node.enq_real >= deq_remain
                node.deq = deq_remain
            end
            deq_remain -= node.deq
        end
    end
    def sch_wrr
        cal_child = @child.dup
        cal_child.delete_if{|node| node.enq_real == 0}
        deq_remain = @deq
        while cal_child != []
            weight_sum = cal_child.sum_weight
            delete_node_index = cal_child.find_first_empty
            sch_speed_block = deq_remain / weight_sum
            if sch_speed_block * cal_child[delete_node_index].weight > cal_child[delete_node_index].enq_real
                sch_speed_block = cal_child[delete_node_index].enq_real / cal_child[delete_node_index].weight
            else
            end
            cal_child.each do |node|
                sch_speed = node.weight * sch_speed_block
                node.deq += sch_speed
                deq_remain -= sch_speed
            end
            cal_child.delete_at(delete_node_index)
        end
    end

    def plug(node)
        @father = node
        node.mount(self)
    end
    def mount(node)
        @child << node
        self << node
    end
    def speed_per_weight
        @enq_real.to_f / @weight
    end
    def print_tree(level = 0)
      if is_root?
        print "*"
      else
        print "|" unless parent.is_last_sibling?
        print(' ' * (level - 1) * 4)
        print(is_last_sibling? ? "+" : "|")
        print "---"
        print(has_children? ? "+" : ">")
      end
      puts " #{name}"" deq:#{@deq}"" enq:#{@enq}"
      children { |child| child.print_tree(level + 1)}
    end
end

# 1.setup sch_node object
sch_level = []
sch_level << fq = (Sch.new('fq_0')..Sch.new('fq_7')).to_a
sch_level << sqp = (Sch.new('sqp_0')..Sch.new('sqp_3')).to_a
sch_level << root = [Sch.new('root_0')]
# 2.cfg sch_tree/shaper/sch_type/fq's enq
fq.each do |node|
    node.plug(sqp.index_id(0))
    node.enq = 125000
end
sqp.each do |node|
    node.plug(root.index_id(0))
    node.sch_type = 'wrr'
end
sqp[0].cir = 450000
sqp[0].eir = 0
# 3.update enq from bottom to top,by level
sch_level.each do |level|
    level.each do |node|
        node.cal_enq.upload_enq
    end
end

# 4.update deq from top to bottom,by prior/level
sch_level.reverse.each do |level|
    level.each do |node|
        node.update_deq
    end
end

# debug
root[0].print_tree
